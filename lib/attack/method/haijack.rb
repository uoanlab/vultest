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

  def meterpreter(args)
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
