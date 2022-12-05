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
  class DesktopCLI
    class << self
      # Used to ensure each user is only running a single command at at time
      # NOTE: These objects will be indefinitely cached in memory until the server
      #       is restarted. This may constitute a memory leak if an indefinite
      #       number of users access the service.
      #       Consider refactoring
      def mutexes
        @mutexes ||= Hash.new { |h, k| h[k] = Mutex.new }
      end

      def index_sessions(user:)
        new(*flight_desktop, 'list', user: user).run_local
      end

      def find_session(id, user:)
        new(*flight_desktop, 'show', id, user: user).run_local
      end

      def start_session(desktop, user:, session_name: nil, geometry: nil)
        if remote_host = select_remote_host(user)
          new(*flight_desktop, 'start', desktop, *name_param(session_name), *geometry_param(geometry), user: user).run_remote(remote_host)
        else
          new(*flight_desktop, 'start', desktop, *name_param(session_name), *geometry_param(geometry), user: user).run_local
        end
      end

      def rename_session(id, name:, user:, remote_host:)
        if remote_host
          new(*flight_desktop, 'rename', id, name, user: user).run_remote(remote_host)
        else
          new(*flight_desktop, 'rename', id, name, user: user).run_local
        end
      end

      def resize_session(id, geometry:, user:, remote_host:)
        if remote_host
          new(*flight_desktop, 'resize', id, geometry, user: user).run_remote(remote_host)
        else
          new(*flight_desktop, 'resize', id, geometry, user: user).run_local
        end
      end

      def configure_session(id, geometry:, name:, user:, remote_host:)
        results = []
        if name.present?
          results << rename_session(id, name: name, user: user, remote_host: remote_host)
        end
        if geometry.present?
          results << resize_session(id, geometry: geometry, user: user, remote_host: remote_host)
        end
        results.compact.last
      end

      def webify_session(id, user:, remote_host:)
        if remote_host
          new(*flight_desktop, 'webify', id, user: user).run_remote(remote_host)
        else
          new(*flight_desktop, 'webify', id, user: user).run_local
        end
      end

      def kill_session(id, user:, remote_host:)
        if remote_host
          new(*flight_desktop, 'kill', id, user: user).run_remote(remote_host)
        else
          new(*flight_desktop, 'kill', id, user: user).run_local
        end
      end

      def clean_session(id, user:, remote_host:)
        if remote_host
          new(*flight_desktop, 'clean', id, user: user).run_remote(remote_host)
        else
          new(*flight_desktop, 'clean', id, user: user).run_local
        end
      end

      def verify_desktop(desktop, user:)
        if remote_host = select_remote_host(user)
          new(*flight_desktop, 'verify', desktop, '--force', user: user).run_remote(remote_host)
        else
          new(*flight_desktop, 'verify', desktop, '--force', user: user).run_local
        end
      end

      def avail_desktops(user:)
        new(*flight_desktop, 'avail', user: user).run_local
      end

      def set(desktop: nil, geometry: nil, user:)
        params = { desktop: desktop, geometry: geometry }
          .reject { |_, v| v.nil? }
          .map { |k, v| "#{k}=#{v}" }
        new(*flight_desktop, 'set', *params, user: user).run_local
      end

      private

      def select_remote_host(user)
        return nil if user == "root"
        Flight.config.remote_host_selector.call
      end

      def flight_desktop
        Flight.config.desktop_command
      end

      def name_param(session_name)
        ["--name", session_name] unless session_name.blank?
      end

      def geometry_param(geometry)
        ["--geometry", geometry] unless geometry.blank?
      end
    end

    def initialize(*cmd, user:, stdin: nil, timeout: nil, env: {})
      @timeout = timeout || Flight.config.command_timeout
      @cmd = cmd
      @user = user
      @stdin = stdin
      @env = {
        'PATH' => Flight.config.command_path,
        'HOME' => passwd.dir,
        'USER' => @user,
        'LOGNAME' => @user,
        'LANG' => Flight.config.lang
      }.merge(env)
    end

    def run_local(&block)
      result =
        self.class.mutexes[@user].synchronize do
          Flight.logger.debug("Running subprocess (#{@user}): #{stringified_cmd}")
          process = Subprocess.new(
            env: @env,
            logger: Flight.logger,
            timeout: @timeout,
            username: @user,
          )
          process.run(@cmd, @stdin, &block)
        end
      parse_result(result)
      log_command(result)
      result
    end

    def run_remote(host, &block)
      result =
        self.class.mutexes[@user].synchronize do
          Flight.logger.debug("Running remote process (#{@user}@#{host}): #{stringified_cmd}")
          public_key_path = Flight.config.ssh_public_key_path

          process = RemoteProcess.new(
            connection_timeout: Flight.config.ssh_connection_timeout,
            env: @env,
            host: host,
            keys: [Flight.config.ssh_private_key_path],
            logger: Flight.logger,
            public_key_path: public_key_path,
            timeout: @timeout,
            username: @user,
          )
          process.run(@cmd, @stdin, &block)
        end
      parse_result(result)
      log_command(result)
      result
    end

    private

    def passwd
      @passwd ||= Etc.getpwnam(@user)
    end

    def parse_result(result)
      if result.exitstatus == 0 && expect_json_response?
        begin
          unless result.stdout.nil? || result.stdout.strip == ''
            result.stdout = JSON.parse(result.stdout)
          end
        rescue JSON::ParserError
          result.exitstatus = 128
        end
      end
    end

    def expect_json_response?
      @cmd.any? {|i| i.strip == '--json'}
    end

    def log_command(result)
      Flight.logger.info <<~INFO.chomp
        COMMAND: #{stringified_cmd}
        USER: #{@user}
        PID: #{result.pid}
        STATUS: #{result.exitstatus}
      INFO
      Flight.logger.debug <<~DEBUG
        ENV:
        #{JSON.pretty_generate @env}
        STDIN:
        #{@stdin.to_s}
        STDOUT:
        #{result.stdout}
        STDERR:
        #{result.stderr}
      DEBUG
    end

    def stringified_cmd
      @stringified_cmd ||= @cmd
        .map { |s| s.empty? ? '""' : s }.join(' ')
    end
  end
end
