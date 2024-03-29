#==============================================================================
# Copyright (C) 2021-present Alces Flight Ltd.
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

module FlightDesktopRestAPI
  autoload(:Configuration, 'flight_desktop_restapi/configuration')
  autoload(:DesktopCLI, 'flight_desktop_restapi/desktop_cli')
  autoload(:InstallPublicSshKey, 'flight_desktop_restapi/install_public_ssh_key')
  autoload(:RemoteHostSelector, 'flight_desktop_restapi/remote_host_selector')
  autoload(:RemoteProcess, 'flight_desktop_restapi/remote_process')
  autoload(:Subprocess, 'flight_desktop_restapi/subprocess')
  autoload(:EnvParser, 'flight_desktop_restapi/env_parser')
end
