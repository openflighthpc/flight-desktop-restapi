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
    class Result < Struct.new(:stdout, :stderr, :exitstatus, :pid)
      def success?
        exitstatus == 0
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
      @stdout = ""
      @stderr = ""
      @exit_code = nil
      @exit_signal = nil
      # @read_threads = []
      # start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      # create_pipes
      run_command(cmd, &block)
      # start_read_threads
      # write_stdin(stdin)
      # status = wait_for_process
      # wait_for_read_threads(start_time)
      # exit_code = determine_exit_code(status)

      Result.new(@stdout, @stderr, @exit_code, nil)
    end

    private

    def run_command(cmd, &block)
      # XXX Add timeout support.
      # XXX Add support for wrting to stdin.
      # XXX Avoid `cmd.join(" ").  Can we not use an array over SSH?

      @logger.debug("Starting SSH session #{@username}@#{@host} with keys #{@keys.inspect}")
      Net::SSH.start(@host, @username, keys: @keys, timeout: @timeout) do |ssh|
        ssh.open_channel do |channel|
          @logger.debug("Exec'ing cmd #{cmd.inspect}")

          env = @env.map { |k, v| "#{k}=#{v}" }.join(" ")
          env_and_cmd = "#{env} #{cmd.join(" ")}"

          channel.exec(env_and_cmd) do |ch, success|
            unless success
              @logger.error("Failed to execute command")
              # XXX Raise an exception of some sort or another.
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
              @logger.debug("Received exit-status: #{data.inspect}")
              @exit_code = data.read_long
            end

            channel.on_request("exit-signal") do |ch, data|
              @logger.debug("Received exit-signal: #{data.inspect}")
              @exit_signal = data.read_long
            end
          end
        end

        ssh.loop
      end
    end
  end
end
