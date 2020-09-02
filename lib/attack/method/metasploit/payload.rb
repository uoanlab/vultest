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

require 'lib/print'

module Attack
  module Method
    module Metasploit
      class Payload
        def initialize(args)
          @msf_api = args[:msf_api]
          @sessions = args[:sessions]
        end

        def exec
          Print.execute('Brake into target machine')

          @sessions.each do |id, value|
            next if value['via_payload'].empty?

            case value['type']
            when 'meterpreter' then exec_meterpreter(id)
            when 'shell' then exec_shell(id)
            else next
            end
          end
        end

        private

        def exec_shell(id)
          loop do
            cmd = gets.chomp
            break if cmd.split(' ')[0] == 'exit'

            @msf_api.shell_write(id: id, cmd: cmd)
            loop do
              res = @msf_api.shell_read(id)
              break if res['data'].empty?

              print res['data']
            end
          end
          @msf_api.session_stop(id)
        end

        def exec_meterpreter(id)
          loop do
            print 'meterpreter > '
            cmd = gets.chomp
            next if cmd.empty?
            break if cmd.split(' ')[0] == 'exit'

            @msf_api.meterpreter_write(id: id, cmd: cmd)
            next if cmd.split(' ')[0] =~ /cd/i || cmd.split(' ')[0] =~ /lcd/i

            loop do
              sleep(1)
              res = @msf_api.meterpreter_read(id)
              break if res['data'].empty?

              Print.stdout(res['data'])
            end
          end
          @msf_api.session_stop(id)
        end
      end
    end
  end
end
