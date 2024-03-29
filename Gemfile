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

source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gem 'activemodel', require: 'active_model'
gem 'activesupport', require: 'active_support/all'
gem 'bcrypt_pbkdf'
gem 'concurrent-ruby'
gem 'dotenv'
gem 'ed25519'
gem 'flight_auth', github: "openflighthpc/flight_auth", branch: "297cb7241b820d334e5d593c4e237a81b83a9995"
gem 'flight_configuration', github: 'openflighthpc/flight_configuration', tag: '0.6.1', branch: 'master'
gem 'hashie'
gem "net-ssh", "~> 6.1"
gem 'puma'
gem 'request_store'
gem 'sinatra', require: 'sinatra/base'
gem 'sinatra-namespace'
gem 'sinatra-cross_origin'

group :development, :test do
  group :pry do
    gem 'pry'
    gem 'pry-byebug'
  end
end

group :test do
  gem 'fakefs', require: 'fakefs/safe'
  gem 'rack-test'
  gem 'rspec'
  gem 'rspec-collection_matchers'
end
