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

require 'lib/print'

module Attack
  module Tool
    class Metasploit
      attr_reader :host, :msf_api, :error, :exploits, :sessions

      ATTACK_TIME_LIMIT = 30
      LOGIN_TIME_LIMIT = 10

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
            { option['name'] => option['var'] }
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
        exploit_info = msf_api.module_execute(
          type: exploit_type,
          name: exploit_name,
          option: exploit_option
        )

        return if success_exploit?(exploit_name, exploit_info)

        @error = {
          name: exploit_name,
          option: exploit_option
        }
      end

      def success_exploit?(exploit_name, exploit_info)
        Print.spinner_begin(exploit_name)
        time_count = 0

        loop do
          time_count += sleep(1)

          if (time_count % ATTACK_TIME_LIMIT).zero?
            Print.spinner_end('error')
            unless TTY::Prompt.new.yes?(
              'There\'s a possibility that attack is fail. Are you still going to continue that?'
            )
              return false
            end

            Print.spinner_begin(exploit_name)
          end

          # When module is auxiliary/scanner/ssh/ssh_login, exploit_info['uuid'] != value['exploit_uuid']
          session = msf_api.module_sessions.select do |_key, value|
            exploit_info['uuid'] == value['exploit_uuid'] ||
              (
                exploit_name == 'auxiliary/scanner/ssh/ssh_login' &&
                exploit_name == value['via_exploit']
              )
          end

          next if session.empty?

          Print.spinner_end('success')
          return !@sessions.merge!(session).empty?
        end
      end

      def exec_payload
        Print.execute('Brake into target machine')

        sessions.each do |id, value|
          next if value['via_payload'].empty?

          case value['type']
          when 'meterpreter' then meterpreter_payload(id: id)
          when 'shell' then shell_payload(id: id)
          else next
          end
        end
      end

      def shell_payload(args)
        loop do
          cmd = gets.chomp
          break if cmd.split(' ')[0] == 'exit'

          msf_api.shell_write(id: args[:id], cmd: cmd)
          loop do
            res = msf_api.shell_read(args[:id])
            break if res['data'].empty?

            print res['data']
          end
        end
        msf_api.session_stop(args[:id])
      end

      def meterpreter_payload(args)
        loop do
          print 'meterpreter > '
          cmd = gets.chomp
          next if cmd.empty?
          break if cmd.split(' ')[0] == 'exit'

          msf_api.meterpreter_write(id: args[:id], cmd: cmd)
          next if cmd.split(' ')[0] =~ /cd/i || cmd.split(' ')[0] =~ /lcd/i

          loop do
            sleep(1)
            res = msf_api.meterpreter_read(args[:id])
            break if res['data'].empty?

            Print.stdout(res['data'])
          end
        end
        msf_api.session_stop(args[:id])
      end
    end
  end
end
