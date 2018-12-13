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
attack_machine_host = nil

vulenv_dir = './test'

# execute prompt
loop do
  print "#{prompt} > "
  input_list = gets.chomp.split(" ")

  case input_list[0]
  when 'test'
    cve = input_list[1]
    vulenv_config_path, attack_config_path = VultestCommand.test(cve, vulenv_dir)
    prompt = cve

  when 'exit'
    break if VultestCommand.exit == 'success'

  when 'exploit'
    TestCommand.exploit(attack_machine_host, attack_config_path)

  when 'set'
    attack_machine_host = TestCommand.set(input_list[1], input_list[2]) if input_list[1] == 'ATTACKER'
    vulenv_dir = TestCommand.set(input_list[1], input_list[2]) if input_list[1] == 'TESTDIR'

  when 'report'
    TestCommand.report(cve, vulenv_config_path)

  when 'destroy'
    TestCommand.destroy(vulenv_dir)

  when 'back'
    prompt = 'vultest'
    attack_machine_host = nil
  end

end
