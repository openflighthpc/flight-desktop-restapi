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

require 'base64'
require 'time'

DesktopCLI = FlightDesktopRestAPI::DesktopCLI

class DesktopConfig < Hashie::Trash
  include Hashie::Extensions::Dash::Coercion

  def self.update(user:, **opts)
    cmd = DesktopCLI.set(user: user, **opts)
    if cmd.success?
      parts = cmd.stdout.split("\n").map { |s| s.split("\s").last }
      new(desktop: parts.first, geometry: parts[1])
    else
      raise InternalServerError
    end
  end

  class << self
    # There is no fetch command for configs in flight-desktop, only set
    alias_method :fetch, :update
  end

  property :desktop
  property :geometry

  def as_json(_ = {})
    {
      'id' => 'user',
      'desktop' => desktop,
      'geometry' => geometry,
      'geometries' => Flight.config.xrandr_geometries
    }
  end

  def to_json
    as_json.to_json
  end
end

class Session < Hashie::Trash
  include Hashie::Extensions::Dash::Coercion

  def self.index(user:)
    cmd = DesktopCLI.index_sessions(user: user)
    if cmd.success?
      cmd.stdout.split("\n").map do |line|
        parts = line.split("\t").map { |p| p.empty? ? nil : p }
        new(
          id: parts[0],
          desktop: parts[1],
          hostname: parts[2],
          primary_ip: parts[3],
          port: parts[5],
          webport: parts[6],
          password: parts[7],
          state: parts[8],
          created_at: parts[9],
          last_accessed_at: parts[10],
          screenshot_path: parts[11],
          user: user,
          ips: (parts[12] || "").split("|"),
          name: parts[13],
          job_id: parts[14]
        )
      end
    else
      raise InternalServerError
    end
  end

  def self.find(id, reload: true, user:)
    cmd = DesktopCLI.find_session(id, user: user)
    if cmd.success?
      session = build_from_output(cmd.stdout.split("\n"), user: user)

      # Stop the recursion
      return session unless reload

      # Checks if the session needs to be webified
      return session unless session.webport == '0' && session.state == 'Active'

      # Webify the session and reload
      DesktopCLI.webify_session(id, user: user, remote_host: session.remote_host)
      find(id, reload: false, user: user)
    else
      # Technically multiple errors conditions could cause the command to fail
      # However the exit code is always the same.
      #
      # It is assumed that the primary reason for the error is because the session is missing
      nil
    end
  end

  def self.build_from_output(lines, user:)
    lines = lines.split("\n") if lines.is_a?(String)
    data = lines.each_with_object({}) do |line, memo|
      parts = line.split(/\t/, 2)
      value = parts.pop
      key = case parts.join(' ')
      when 'Identity'
        :id
      when 'Host IP'
        :primary_ip
      when 'Hostname'
        :hostname
      when 'Port'
        :port
      when 'Password'
        :password
      when 'Type'
        :desktop
      when 'State'
        :state
      when 'WebSocket Port'
        :webport
      when 'Created At'
        :created_at
      when 'Last Accessed At'
        :last_accessed_at
      when 'Screenshot Path'
        :screenshot_path
      when 'IPs'
        value = value.split("|")
        :ips
      when 'Name'
        value = nil if value.blank?
        :name
      when 'Job ID'
        value = nil if value.blank?
        :job_id
      when 'Geometry'
        :geometry
      when 'Available Geometries'
        value = value.split("|")
        :available_geometries
      when 'Capabilities'
        value = value.split("|")
        :capabilities
      else
        next # Ignore any extraneous keys
      end
      memo[key] = value
    end
    new(user: user, **data)
  end

  property :id
  property :desktop
  property :primary_ip
  property :ips
  property :hostname
  property :port, coerce: String
  property :webport, coerce: String
  property :password
  property :user
  property :state
  property :name
  property :job_id
  property :geometry
  property :available_geometries
  property :capabilities
  property :created_at, transform_with: ->(time) {
    case time
    when Time
      time
    when NilClass, ''
      nil
    else
      Time.parse(time.to_s)
    end
  }
  property :last_accessed_at, transform_with: ->(time) {
    case time
    when Time
      time
    when NilClass, ''
      nil
    else
      Time.parse(time.to_s)
    end
  }
  property :screenshot_path, transform_with: ->(path) do
    path = path.to_s
    path.empty? ? nil : path
  end

  def screenshot
    @screenshot || false
  end

  def load_screenshot
    @screenshot ||= Screenshot.new(self).read
  end

  def ip
    return primary_ip if ips.nil? || ips.empty?
    return primary_ip if Flight.config.websocket_ip_range.nil?

    selected = ips.detect { |ip| Flight.config.websocket_ip_range.include?(ip) }
    selected || primary_ip
  end

  def to_json
    as_json.to_json
  end

  def as_json(_ = {})
    {
      'id' => id,
      'desktop' => desktop,
      'ip' => ip,
      'hostname' => hostname,
      'port' => webport,
      'password' => password,
      'state' => state,
      'created_at' => created_at&.rfc3339,
      'last_accessed_at' => last_accessed_at&.rfc3339,
      'name' => name,
      'job_id' => job_id,
      'geometry' => geometry,
      'available_geometries' => available_geometries,
      'capabilities' => capabilities,
    }.tap do |h|
      h['screenshot'] = screenshot ? Base64.encode64(screenshot) : nil
    end
  end

  def kill(user:)
    cmd = DesktopCLI.kill_session(id, user: user, remote_host: remote_host)
    return true if cmd.success?
    cmd = DesktopCLI.clean_session(id, user: user, remote_host: remote_host)
    return true if cmd.success?
    raise InternalServerError.new(detail: 'failed to delete the session')
  end

  def clean(user:)
    if DesktopCLI.clean_session(id, user: user, remote_host: remote_host).success?
      true
    else
      raise InternalServerError.new(detail: 'failed to clean the session')
    end
  end

  def rename(name:)
    if DesktopCLI.rename_session(id, name: name, user: user, remote_host: remote_host).success?
      true
    else
      raise InternalServerError.new(detail: 'failed to rename the session')
    end
  end

  def resize(geometry:)
    unless capabilities.include?("resizable")
      raise BadRequest.new(detail: "session type is not resizable")
    end
    if DesktopCLI.resize_session(id, geometry: geometry, user: user, remote_host: remote_host).success?
      true
    else
      raise InternalServerError.new(detail: 'failed to resize the session')
    end
  end

  def configure(name:, geometry:)
    if geometry.present? && !capabilities.include?("resizable")
      raise BadRequest.new(detail: "session type is not resizable")
    end
    if DesktopCLI.configure_session(
        id,
        name: name,
        geometry: geometry,
        user: user,
        remote_host: remote_host
    ).success?
      true
    else
      raise InternalServerError.new(detail: 'failed to configure the session')
    end
  end


  def remote_host
    remote? ? hostname : nil
  end

  def remote?
    state == 'Remote'
  end
end

class Desktop < Hashie::Trash
  def self.index
    cache.values
  end

  def self.[](key)
    cache[key]
  end

  def self.avail
    DesktopCLI.avail_desktops(user: ENV['USER'])
      .tap { |result| raise InternalServerError unless result.success? }
      .stdout
      .each_line
      .map do |line|
        data = line.split("\t")
        home = data[2].empty? ? nil : data[2]
        verified = (data[3].chomp == 'Verified')
        new(name: data[0], summary: data[1], homepage: home, verified: verified)
    end
  end

  def self.default(user:)
    config = DesktopConfig.fetch(user: user)
    self[config.desktop]
  end

  private_class_method

  # This is set during the desktop initializer
  def self.cache
    @cache ||= {}
  end

  property :name
  property :verified, default: false
  property :summary, default: ''
  property :homepage

  def to_json
    as_json.to_json
  end

  def as_json(_ = {})
    {
      'id' => name,
      'verified' => verified?,
      'summary' => summary,
      'homepage' => homepage
    }
  end

  def verified?
    if Flight.config.verified_desktops.include?(name)
      true
    else
      verified
    end
  end

  # NOTE: The start_session will attempt to verify the desktop if required
  # GOTCHA: Because the system command always exits 1 on errors, the
  #         verified/ missing toggle is based on string processing.
  #
  #         This makes the toggle brittle as a minor change in error message
  #         could break the regex match. Instead `flight desktop` should be
  #         updated to return different exit codes
  def start_session!(user:, session_name: nil, geometry: nil)
    cmd = DesktopCLI.start_session(name, user: user, session_name: session_name, geometry: geometry)
    if /verified\Z/ =~ cmd.stderr
      verify_desktop!(user: user)
      cmd = DesktopCLI.start_session(name, user: user, session_name: session_name, geometry: geometry)
    end
    raise InternalServerError unless cmd.success?
    Session.build_from_output(cmd.stdout.split("\n"), user: user)
  end

  def verify_desktop(user:)
    cmd = DesktopCLI.verify_desktop(name, user: user)
    self.verified = if /already been verified\.\Z/ =~ cmd.stdout.chomp
      true
    elsif /^\s*(flight)? desktop prepare\b/ =~ cmd.stdout
      false
    elsif cmd.success?
      true
    else
      false
    end
  end

  def verify_desktop!(user:)
    raise DesktopNotPrepared unless verify_desktop(user: user)
  end
end

Screenshot = Struct.new(:session) do
  def base64_encode
    Base64.encode64(read)
  end

  def read!
    read || raise(NotFound.new(id: session.id, type: 'screenshot'))
  end

  def read
    path = session.screenshot_path
    return nil unless path
    File.exists?(path) ? File.read(path) : nil
  end
end

