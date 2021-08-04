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

require_relative 'config/boot'

# Ensures the shared secret exists
FlightDesktopRestAPI.config.auth_decoder

require_relative 'config/initializers'
require_relative 'app'

require 'sinatra'

configure do
  set :show_exceptions, :after_handler
  set :logger, DEFAULT_LOGGER
  enable :logging
end

at_exit do
  # Disable the flight-desktop integration on exit
  FileUtils.rm_f FlightDesktopRestAPI.config.integrated_reload_dst
end

app = Rack::Builder.new do
  map('/v2') { run Sinatra::Application }
end

run app
