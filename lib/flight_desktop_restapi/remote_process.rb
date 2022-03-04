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

require 'etc'
require 'timeout'
require 'net/ssh'

module FlightDesktopRestAPI
  class RemoteProcess
    class Result < Struct.new(:stdout, :stderr, :exitstatus)
      def success?
        exitstatus == 0
      end

      def pid
        "<Unknown: Remote process>"
      end
    end

    def initialize(host:, env:, logger:, timeout:, username:, keys:, **ignored)
      @host = host
      @env = env
      @logger = logger
      @passwd = Etc.getpwnam(username)
      @timeout = timeout
      @username = username
      @keys = keys
    end

    def run(cmd, stdin, &block)
      # XXX Add support for wrting to stdin.
      @stdout = ""
      @stderr = ""
      @exit_code = nil
      @exit_signal = nil

      with_timout do
        run_command(cmd, &block)
      end

      Result.new(@stdout, @stderr, determine_exit_code)
    end

    private

    def with_timout(&block)
      Timeout.timeout(@timeout, &block)
    rescue Timeout::Error
      @logger.info("Aborting remote process; timeout exceeded.")
    end

    def run_command(cmd, &block)
      @logger.info("Starting SSH session #{cmd_debug(cmd)} keys=#{@keys.inspect}")
      Net::SSH.start(@host, @username, keys: @keys) do |ssh|
        ssh.open_channel do |channel|
          @logger.debug("SSH session started. Executing cmd #{cmd_debug(cmd)}")
          channel.exec(cmd_string(cmd)) do |ch, success|
            unless success
              @logger.error("Failed to execute command")
            end

            channel.on_data do |ch, data|
              @logger.debug("Received stdout data: #{data.inspect}")
              @stdout << data
            end

            channel.on_extended_data do |ch, type, data|
              @logger.debug("Received stderr data: #{data.inspect}")
              @stderr << data
            end

            channel.on_request("exit-status") do |ch, data|
              @exit_code = data.read_long
              @logger.debug("Received exit-status: #{@exit_code}")
            end

            channel.on_request("exit-signal") do |ch, data|
              @exit_signal = data.read_long
              @logger.debug("Received exit-signal: #{@exit_signal}")
            end
          end
        end

        ssh.loop
      end
    end

    def determine_exit_code
      if @exit_signal
        @logger.debug "Inferring exit code from signal"
        @exit_signal + 128
      elsif @exit_code
        @exit_code
      else
        @logger.debug "No exit code provided"
        128
      end
    end

    def cmd_string(cmd)
      env_string = @env.map { |k, v| "#{k}=#{v}" }.join(" ")
      [env_string, *cmd].join(" ")
    end

    def cmd_debug(cmd)
      "(#{@username}@#{@host}) #{cmd.join(" ")}"
    end
  end
end
