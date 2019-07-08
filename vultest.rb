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

require 'bundler/setup'
require 'optparse'
require 'pastel'
require 'tty-font'

require_relative './process/vultest'
require_relative './console'
require_relative './option'
require_relative './ui'

unless ARGV.size.zero?
  options = ARGV.getopts('h', 'cve:', 'test:yes', 'attack_user:', 'attack_passwd:', 'attack_host:', 'dir:', 'destroy:')
  VultestOptionExecute.execute(options)
  exit!
end

console = VultestConsole.new
loop do
  print "#{console.prompt} > "
  command = gets.chomp.split(' ')

  case command[0]
  when /test/i
    console.test_command(command[1])
  when /exit/i
    break
  when /exploit/i
    console.exploit_command
  when /set/i
    console.option_command(command)
  when /report/i
    console.report_command
  when /destroy/i
    console.destroy_command
  when /back/i
    console = VultestConsole.new
  when nil
    next
  else
    VultestUI.print_vultest_message('error', 'command not found')
  end
end
