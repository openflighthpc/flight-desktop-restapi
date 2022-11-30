# =============================================================================
# Copyright (C) 2022-present Alces Flight Ltd.
#
# This file is part of Flight Desktop RestAPI.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Flight Desktop RestAPI is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Flight Desktop RestAPI. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Flight Desktop RestAPI, please visit:
# https://github.com/openflighthpc/flight-desktop-restapi
# ==============================================================================
# Adapted from https://github.com/bkeepers/dotenv/blob/9e16a424083055139e62d60a55bd0fec53003cee/lib/dotenv/parser.rb
#
# Copyright (c) 2012 Brandon Keepers
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
module FlightDesktopRestAPI
  module EnvParser
    LINE = /
      (?:^|\A)              # beginning of line
      \s*                   # leading whitespace
      ([\w\.]+)             # key
      (?:\s*=\s*?|:\s+?)    # separator
      (                     # optional value begin
        \s*'(?:\\'|[^'])*'  #   single quoted value
        |                   #   or
        \s*"(?:\\"|[^"])*"  #   double quoted value
        |                   #   or
        [^\#\r\n]+          #   unquoted value
      )?                    # value end
      \s*                   # trailing whitespace
      (?:\#.*)?             # optional comment
      (?:$|\z)              # end of line
    /x

    class << self
      def parse(string)
        {}.tap do |h|
          # Convert line breaks to same format
          lines = string.gsub(/\r\n?/, "\n")
          # Process matches
          lines.scan(LINE).each do |key, value|
            h[key] = parse_value(value || "")
          end
        end
      end

      private

      def parse_value(value)
        # Remove surrounding quotes
        value = value.strip.sub(/\A(['"])(.*)\1\z/m, '\2')

        if Regexp.last_match(1) == '"'
          value = unescape_characters(expand_newlines(value))
        end

        value
      end

      def unescape_characters(value)
        value.gsub(/\\([^$])/, '\1')
      end

      def expand_newlines(value)
        value.gsub('\n', "\n").gsub('\r', "\r")
      end
    end
  end
end
