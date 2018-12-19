require 'bundler/setup'
require 'pastel'
require 'tty-font'

require_relative './commands/test_command.rb'
require_relative './commands/vultest_command.rb'

# vultest title
font = TTY::Font.new(:"3d")
pastel = Pastel.new
puts pastel.red(font.write("VULTEST"))

# pormpt and option initialize
prompt = 'vultest'
cve = nil
vulenv_config_path = nil
attack_config_path = nil

testdir = './test'
testdir = ENV['TESTDIR'] if ENV.key?('TESTDIR')

attacker = nil
attacker = ENV['ATTACKER'] if ENV.key?('ATTACKER')

# execute prompt
loop do
  print "#{prompt} > "
  input_list = gets.chomp.split(" ")

  case input_list[0]
  when 'test'
    cve = input_list[1]
    vulenv_config_path, attack_config_path = VultestCommand.test(cve, testdir)
    prompt = cve

  when 'exit'
    break if VultestCommand.exit == 'success'

  when 'exploit'
    TestCommand.exploit(attacker, testdir, vulenv_config_path, attack_config_path)

  when 'set'
    attacker = TestCommand.set(input_list[1], input_list[2]) if input_list[1] == 'ATTACKER'
    testdir = TestCommand.set(input_list[1], input_list[2]) if input_list[1] == 'TESTDIR'

  when 'report'
    TestCommand.report(cve, vulenv_config_path)

  when 'destroy'
    TestCommand.destroy(testdir)

  when 'back'
    prompt = 'vultest'
  end

end
