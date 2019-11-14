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
      command = gets.chomp.split(' ')[0]
      next if command.nil?
      return if command == 'exit'

      args[:api].shell_write(id: args[:id], command: command)
      loop do
        res = args[:api].shell_read(args[:id])
        break if res['data'].empty?

        print res['data']
      end
    end
    args[:api].session_stop(args[:id])
  end

  def meterpreter(args)
    loop do
      print 'meterpreter > '
      command = gets.chomp.split(' ')[0]
      next if command.nil?
      break if command == 'exit'

      args[:api].meterpreter_write(id: args[:id], command: command)
      flag = false
      loop do
        res = args[:api].meterpreter_read(args[:id])
        break if res['data'].empty? && flag
        next if res['data'].empty?

        puts res['data']
        flag = true
      end
    end
    args[:api].session_stop(args[:id])
  end
end
