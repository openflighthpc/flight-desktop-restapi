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
opts = {
  execution_interval: FlightDesktopRestAPI.config.refresh_rate,
  timeout_interval: (FlightDesktopRestAPI.config.refresh_rate - 1),
  run_now: true
}
Concurrent::TimerTask.new(**opts) do |task|
  # Determine which desktops are available.  A `verify --force` is ran for
  # each desktop to ensure we have an accurate list.
  models = Desktop.avail
  if first
    # The first go round, populate the list of available desktops as soon as
    # possible.  Whether they are verified or not may not be entirely
    # accurate, but this is better than having no desktop types to display.
    hash = models.map { |m| [m.name, m] }.to_h
    Desktop.instance_variable_set(:@cache, hash)
  end

  models.each do |m|
    sleep FlightDesktopRestAPI.config.verify_sleep
    m.verify_desktop(user: ENV['USER'])
  end
  hash = models.map { |m| [m.name, m] }.to_h
  Desktop.instance_variable_set(:@cache, hash)

  DEFAULT_LOGGER.info "Finished #{'re' unless first}loading the desktops"
  first = false
end.execute
