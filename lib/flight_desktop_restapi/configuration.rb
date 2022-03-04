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

require 'active_support/core_ext/hash/keys'
require 'active_model'

require 'flight_configuration'
module FlightDesktopRestAPI
  class ConfigError < StandardError; end

  class Configuration
    include FlightConfiguration::DSL
    include FlightConfiguration::RichActiveValidationErrorMessage
    include ActiveModel::Validations

    application_name 'flight-desktop-restapi'
    user_config_files false

    attribute :bind_address, default: 'tcp://127.0.0.1:915'
    validates :bind_address, presence: true

    attribute :cors_domain,  required: false

    attribute :refresh_rate, default: 3600,
      transform: :to_i
    validates :refresh_rate, numericality: true, allow_blank: false

    attribute :shared_secret_path, default: 'etc/shared-secret.conf',
      transform: relative_to(root_path)

    attribute :sso_cookie_name, default: 'flight_login'

    attribute :desktop_command,
      default: File.join(ENV.fetch('flight_ROOT', '/opt/flight'), 'bin/flight desktop'),
      transform: ->(value) { value.split(' ') }
    validates :desktop_command, presence: true
    validate { is_array(:desktop_command) }

    attribute :command_path, default: '/usr/sbin:/usr/bin:/sbin:/bin'
    validates :command_path, presence: true

    attribute :command_timeout, default: 30,
      transform: :to_f
    validates :command_timeout, numericality: true, allow_blank: false

    attribute :remote_hosts, default: [],
      transform: ->(v) { v.is_a?(Array) ? v : v.to_s.split }
    validate { is_array(:remote_hosts) }

    attribute :ssh_connection_timeout, default: 5,
      transform: :to_i
    validates :ssh_connection_timeout, numericality: { greater_than: 0 }, allow_blank: false

    attribute :ssh_private_key_path, default: "etc/desktop-restapi/id_rsa",
      transform: relative_to(root_path)
    validates :ssh_private_key_path, presence: true
    # XXX Validate that the path exists and is readable.

    attribute :log_path, required: false,
              default: '/dev/stdout',
              transform: ->(path) do
                if path
                  relative_to(root_path).call(path).tap do |full_path|
                    FileUtils.mkdir_p File.dirname(full_path)
                  end
                else
                  $stderr
                end
              end

    attribute :log_level, default: 'info'
    validates :log_level, inclusion: {
      within: %w(fatal error warn info debug disabled),
      message: 'must be one of fatal, error, warn, info, debug or disabled'
    }

    attribute :xrandr_geometries,
      transform: ->(v) { v.is_a?(Array) ? v : v.to_s.split(',') },
      default: [
        "1920x1200",
        "1920x1080",
        "1600x1200",
        "1680x1050",
        "1400x1050",
        "1360x768",
        "1280x1024",
        "1280x960",
        "1280x800",
        "1280x720",
        "1024x768",
        "800x600",
        "640x480"
      ]
    validate { is_array(:xrandr_geometries) }

    attribute :verified_desktops, default: [],
      transform: ->(v) { v.is_a?(Array) ? v : v.to_s.split }
    validate { is_array(:verified_desktops) }

    attribute :verify_sleep, default: 0.5, transform: :to_f
    validates :verify_sleep, numericality: true, allow_blank: false

    validate do
      begin
        auth_decoder
      rescue
        errors.add(:shared_secret_path, $!.message)
      end
    end

    def auth_decoder
      @auth_decoder ||= FlightAuth::Builder.new(shared_secret_path)
    end

    private

    def is_array(attr)
      value = send(attr)
      errors.add(attr, "must be an array") unless value.is_a?(Array)
    end
  end
end
