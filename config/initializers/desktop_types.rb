# frozen_string_literal: true

#==============================================================================
# Copyright (C) 2020-present Alces Flight Ltd.
#
# This file is part of FlightDesktopRestAPI.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# FlightDesktopRestAPI is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with FlightDesktopRestAPI. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on FlightDesktopRestAPI, please visit:
# https://github.com/openflighthpc/flight-desktop-restapi
#===============================================================================

# NOTE: All desktops must be stubbed in the spec
return if ENV['RACK_ENV'] == 'test'

first = true

# Periodically reload and verify the desktops
# NOTE: This shouldn't have a timeout as it risks the trap not being reset
#       Instead this should run in-frequently enough that a timeout isn't required
opts = {
  execution_interval: FlightDesktopRestAPI.config.refresh_rate,
  run_now: true
}
Concurrent::TimerTask.new(**opts) do |task|
  # Get the current available desktops
  models = Desktop.avail

  old_usr2_trap = nil
  begin
    # Disable SIGUSR1 and SIGUSR2
    # The flight desktop post-verify *may* attempt a reload by sending USR2
    # This can result in an infinite reload loop. Instead USR2 needs to be temporarily
    # disabled.
    usr2_count = 0
    old_usr2_trap = trap('USR2') { usr2_count+=1 }

    # Verify each of the desktops
    models.each { |m| m.verify_desktop(user: ENV['USER']) }
    hash = models.map { |m| [m.name, m] }.to_h
    Desktop.instance_variable_set(:@cache, hash)

    DEFAULT_LOGGER.info "Finished #{'re' unless first}loading the desktops"
    first = false

  ensure
    # Re-enable reloads
    trap('USR2', old_usr2_trap) if old_usr2_trap
  end

  # Checks if USR2 was received the expected number of times
  # NOTE: flight-desktop will either send USR2 once for every desktop or not at all
  # Any other amount indicates the user sent USR2 and the workers should restart
  num_verified = models.select(&:verified).length
  Process.kill('USR2', Process.pid) unless [0, num_verified].include?(usr2_count)
end.execute
