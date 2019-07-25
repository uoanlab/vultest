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

require_relative './console/vultest_console'
require_relative './option'

unless ARGV.size.zero?
  options = ARGV.getopts('h', 'cve:', 'test:yes', 'attack_user:', 'attack_passwd:', 'attack_host:', 'dir:', 'destroy:')
  VultestOptionExecute.execute_vultest(options)
  exit!
end

console = VultestConsole.new
console.initialize_prompt
console.initialize_vultest_process

loop do
  command = console.prompt.ask("#{console.prompt_name} >")
  command.nil? ? next : command = command.split(' ')

  case command[0]
  when /test/i then console.execute_test_command(cve: command[1])
  when /exit/i then break
  when /exploit/i then console.execute_exploit_command
  when /set/i then console.execute_option_command(option_type: command[1], option_value: command[2])
  when /report/i then console.execute_report_command
  when /destroy/i then console.execute_destroy_command
  when /back/i
    if console.execute_back_command
      console.prompt_name = 'vultest'
      console.initialize_vultest_process
    end
  else console.prompt.error("vultest: command not found: #{command[0]}")
  end
end
