=begin
Copyright [2019] [Kohei Akasaka]

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=end

require 'bundler/setup'
require 'optparse'
require 'pastel'
require 'tty-font'

require_relative './utility.rb'
require_relative './commands/test_command.rb'
require_relative './commands/vultest_command.rb'

# setting initialize var
testdir = './test'
testdir = ENV['TESTDIR'] if ENV.key?('TESTDIR')

attacker = nil
attacker = ENV['ATTACKER'] if ENV.key?('ATTACKER')

cve = nil
vulenv_config_path = nil
attack_config_path = nil

if ARGV.size != 0
  options = ARGV.getopts('d', 'cve:', 'attacker:', 'dir:')

  exit! if options['cve'].nil?
  cve = options['cve']

  # setting options
  attacker = options['attacker'] unless options['attacker'].nil?
  testdir = options['dir'] unless options['dir'].nil?

  # execute vulnerable test
  begin
    vulenv_config_path, attack_config_path = VultestCommand.test(cve, testdir)
  rescue
    Utility.print_message('error', "Cannot test #{cve}")
    exit!
  end

  begin
    TestCommand.exploit(attacker, testdir, vulenv_config_path, attack_config_path)
    TestCommand.report(cve, vulenv_config_path, attack_config_path)
  rescue
    retry
  end

  TestCommand.destroy(testdir) if options['d']

  exit!
end

# vultest title
font = TTY::Font.new(:"3d")
pastel = Pastel.new
puts pastel.red(font.write("VULTEST"))

# pormpt and option initialize
prompt = 'vultest'

# execute prompt
loop do
  print "#{prompt} > "
  input_list = gets.chomp.split(" ")

  case input_list[0]
  when 'test'
    cve = input_list[1]

    begin
      vulenv_config_path, attack_config_path = VultestCommand.test(cve, testdir)
    rescue
      Utility.print_message('error', "Cannot test #{cve}")
      TestCommand.destroy(testdir)
    end

    unless vulenv_config_path.nil? && attack_config_path.nil?
      prompt = cve
    end

  when 'exit'
    break if VultestCommand.exit == 'success'

  when 'exploit'
    begin
      TestCommand.exploit(attacker, testdir, vulenv_config_path, attack_config_path)
    rescue
      Utility.print_message('error', "Cannot exploit")
      TestCommand.destroy(testdir)
    end

  when 'set'
    if input_list.length != 3
      Utility.print_message('error', 'Inadequate option')
      next
    end
    attacker = TestCommand.set(input_list[1], input_list[2]) if input_list[1] == 'ATTACKER'
    testdir = TestCommand.set(input_list[1], input_list[2]) if input_list[1] == 'TESTDIR'

  when 'report'
    begin
      TestCommand.report(cve, vulenv_config_path, attack_config_path)
    rescue
      Utility.print_message('error', 'Cannot output vulnerable report')
      TestCommand.destroy(testdir)
    end

  when 'destroy'
    TestCommand.destroy(testdir)

  when 'back'
    prompt = 'vultest'

  when nil
    next

  else
    Utility.print_message('error', 'command not found')
  end

end
