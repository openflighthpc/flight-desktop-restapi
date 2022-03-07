#==============================================================================
# Copyright (C) 2022-present Alces Flight Ltd.
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

require 'etc'
require 'pathname'
require 'securerandom'

module FlightDesktopRestAPI
  class RemoteHostSelector
    def initialize(hosts)
      @hosts = hosts
      @idx = -1
    end

    def call
      ( get_from_cache || round_robin ).tap do |host|
        set_in_cache(host)
      end
    end

    private

    def round_robin
      @idx += 1
      @idx = 0 if @idx > @hosts.length - 1
      @hosts[@idx].tap do |host|
        Flight.logger.debug("Round robin to host idx=#{@idx} host=#{host}")
      end
    end

    def get_from_cache
      cache_id = "remote_host_selector"
      RequestStore[cache_id].tap do |host|
        Flight.logger.debug("Host from cache host=#{host}")
      end
    end

    def set_in_cache(host)
      cache_id = "remote_host_selector"
      RequestStore[cache_id] = host
    end

  end
end
