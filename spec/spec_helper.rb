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

ENV['RACK_ENV'] = 'test'
require_relative '../config/boot.rb'

module RSpecSinatraMixin
  include Rack::Test::Methods

  def app()
    Sinatra::Application.new
  end
end

module SharedSpecContext
  extend RSpec::SharedContext

  let(:exit_213_stub) { SystemCommand.new(code: 213) }
  let(:exit_0_stub) { SystemCommand.new(code: 0) }

  let(:username) { 'default-test-user' }
  let(:password) { 'default-test-password' }

  let(:cache_dir) { "/home/#{username}/.cache" }

  def define_desktop(name, verified: true)
    Desktop.new(name: name.to_s, verified: verified).tap do |model|
      Desktop.instance_variable_get(:@cache)[model.name] = model
    end
  end

  around do |example|
    Desktop.instance_variable_set(:@cache, {})
    example.call
    Desktop.instance_variable_set(:@cache, nil)
  end
end

RSpec.configure do |c|
	# Include the Sinatra helps into the application
	c.include RSpecSinatraMixin

  # Include the username and password
  c.include SharedSpecContext

  def parse_last_request_body
    json = JSON.parse(last_request.body)
    if json.is_a?(Array)
      json.map { |x| Hashie::Mash.new(x) }
    else
      Hashie::Mash.new(json)
    end
  end

  def parse_last_response_body
    json = JSON.parse(last_response.body)
    if json.is_a?(Array)
      json.map { |x| Hashie::Mash.new(x) }
    else
      Hashie::Mash.new(json)
    end
  end

  def last_error
    last_request.env['sinatra.error']
  end

  def standard_get_headers
    $stdout = StringIO.new
    FlightAuth::CLI.new(Flight.config.shared_secret_path, 'desktop-restapi-test')
                   .run
    $stdout.rewind
    header 'Authorization', "Bearer #{$stdout.read.chomp}"
  ensure
    $stdout = STDOUT
  end

  def standard_post_headers
    standard_get_headers
    header 'Content-Type', 'application/json'
  end

  # Enable FakeFS
  c.around do |example|
    FakeFS.with do
      FakeFS::FileSystem.clone Flight.config.shared_secret_path
      example.call
    end
  end

  c.before do
    # Disable the SystemCommand::Builder from creating commands
    # This forces all system commands to be mocked
    allow(SystemCommand::Builder).to receive(:new).and_wrap_original do |_, *a|
      raise NotImplementedError, <<~ERROR.squish
        Running system commands is not supported in the spec. The following
        needs to be stubbed: '#{a.first}'
      ERROR
    end
  end
end

