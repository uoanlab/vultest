# Copyright [2019] [University of Aizu]
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

module HaijackMethod
  private

  def shell(msf_api, session_id)
    loop do
      print 'shell > '
      command = gets.chomp.split(' ')[0]
      next if command.nil?
      return if command == 'exit'

      msf_api.shell_write(session_id, command)
      success_flag = false
      60.times do
        sleep(1)
        res = msf_api.shell_read(session_id)
        next if res['data'].empty?

        puts res['data']
        success_flag = true
        break
      end
      puts 'Command not fund or incorrect how to use the command' unless success_flag
    end
  end

  def meterpreter(msf_api, session_id)
    loop do
      print 'meterpreter > '
      command = gets.chomp.split(' ')[0]
      next if command.nil?
      break if command == 'exit'

      msf_api.meterpreter_write(session_id, command)
      success_flag = false
      60.times do
        sleep(1)
        res = @msf_api.meterpreter_read(session_id)
        next if res['data'].empty?

        puts res['data']
        success_flag = true
        break
      end
      puts 'Command not fund or incorrect how to use the command' unless success_flag
    end
  end
end
