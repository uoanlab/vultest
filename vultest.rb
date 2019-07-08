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
require_relative './option'
require_relative './ui'

vultest_processing = ProcessVultest.new

unless ARGV.size.zero?
  options = ARGV.getopts('h', 'cve:', 'test:yes', 'attack_user:', 'attack_passwd:', 'attack_host:', 'dir:', 'destroy:')
  VultestOptionExecute.execute(vultest_processing, options)
  exit!
end

font = TTY::Font.new(:"3d")
pastel = Pastel.new
puts pastel.red(font.write("VULTEST"))

prompt = 'vultest'
loop do
  print "#{prompt} > "
  command = gets.chomp.split(" ")

  case command[0]
  when /test/i
    vultest_processing.create_vulenv(command[1])
    prompt = vultest_processing.cve unless vultest_processing::cve.nil?

  when /exit/i
    break

  when /exploit/i
    vultest_processing.attack_vulenv

  when /set/i
    if command.length != 3
      VultestUI.print_vultest_message('error', 'Inadequate option')
      next
    end

    if command[1] =~ /testdir/i
      unless vultest_processing::cve.nil?
        VultestUI.print_vultest_message('error', 'Cannot execute set command')
        next
      end

      path = ''
      path_elm = command[2].split("/")

      path_elm.each do |elm|
        path.concat('/') unless path.empty?
        if elm[0] == '$'
          elm.slice!(0)
          ENV.key?(elm) ? path.concat(ENV[elm]) : path.concat(elm)
        else path.concat(elm)
        end
      end
      vultest_processing.test_dir = path
      puts "TESTDIR => #{vultest_processing.test_dir}"
    elsif command[1] =~ /attackhost/i 
      vultest_processing.attack[:host] = command[2]
      puts "ATTACKHOST => #{vultest_processing.attack[:host]}"
    elsif command[1] =~ /attackuser/i 
      vultest_processing.attack[:user] = command[2]
      puts "ATTACKERUSER => #{vultest_processing.attack[:user]}"
    elsif command[1] =~ /attackpasswd/i 
      vultest_processing.attack[:passwd] = command[2]
      puts "ATTACKPASSWD => #{vultest_processing.attack[:passwd]}"
    else puts "Not fund option (#{command[1]})"
    end

  when /report/i
    vultest_processing.execute_vultest_report

  when /destroy/i
    vultest_processing.destroy_vulenv!

  when /back/i
    prompt = 'vultest'
    vultest_processing = ProcessVultest.new

  when nil
    next

  else
    VultestUI.print_vultest_message('error', 'command not found')
  end

end
