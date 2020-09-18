# Copyright [2020] [University of Aizu]
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'lib/api/metasploit'
require 'lib/attack/method/metasploit/exploit'
require 'lib/attack/method/metasploit/payload'
require 'lib/print'

module Attack
  module Method
    module Metasploit
      ATTACK_TIME_LIMIT = 30
      LOGIN_TIME_LIMIT = 10

      class Core
        attr_reader :host, :msf_api, :error, :exploits, :sessions

        def initialize(args)
          @host = args[:host]

          @exploits = args[:exploits]
          @sessions = {}

          # @error = { name: nil, option: [] }
          @error = nil
        end

        def exec
          prepare_metasploit_api
          exploits.each do |exploit|
            exploit_option = exploit['options'].map do |option|
              { option['name'] => option['value'] }
            end.inject(:merge)
            exploit_option['LHOST'] = host

            exec_exploit(exploit['module_type'], exploit['module_name'], exploit_option)

            break unless error.nil?
          end

          if !error.nil?
            Print.result('failure')
            Print.warring('Can look at a report about error in attack execution')
          else
            Print.result('success')
            print "\n"

            exec_payload
          end
        end

        private

        def prepare_metasploit_api
          @msf_api ||= API::Metasploit.new(host)

          time = 0
          begin
            msf_api.auth_login
          rescue Errno::ECONNREFUSED => e
            sleep(1)
            time += 1
            retry if time < LOGIN_TIME_LIMIT
            Print.error(e)
          end

          msf_api.console_create
        end

        def exec_exploit(exploit_type, exploit_name, exploit_option)
          exploit = Exploit.new(
            msf_api: msf_api,
            type: exploit_type,
            name: exploit_name,
            option: exploit_option
          )
          @error = exploit.exec

          @sessions.merge!(exploit.session) if @error.nil?
        end

        def exec_payload
          payload = Payload.new(msf_api: msf_api, sessions: sessions)
          payload.exec
        end
      end
    end
  end
end
