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
#

module Haijack
  private

  def shell(args)
    loop do
      cmd = gets.chomp.split(' ')[0]
      next if cmd.nil?
      return if cmd == 'exit'

      puts execute_cmd_of_shell(id: args[:id], cmd: cmd)
    end
    msf_api.session_stop(args[:id])
  end

  def meterpreter(args)
    loop do
      print 'meterpreter > '
      cmd = gets.chomp.split(' ')[0]
      next if cmd.nil?
      break if cmd == 'exit'

      puts execute_cmd_of_meterpreter(id: args[:id], cmd: cmd)
    end
    msf_api.session_stop(args[:id])
  end

  def execute_cmd_of_shell(args)
    msf_api.shell_write(id: args[:id], cmd: args[:cmd])
    output = ''
    loop do
      res = msf_api.shell_read(args[:id])
      break if res['data'].empty?

      output = res['data']
    end
    output
  end

  def execute_cmd_of_meterpreter(args)
    msf_api.meterpreter_write(id: args[:id], cmd: args[:cmd])
    flag = false
    output = ''
    loop do
      res = msf_api.meterpreter_read(args[:id])
      break if flag
      next if res['data'].empty?

      output = res['data']
      flag = true
    end
    output
  end
end
