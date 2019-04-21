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
  options = ARGV.getopts('c:', 'a:', 't:', 'd')

  exit! if options['c'].nil?
  cve = options['c']

  # setting options
  attacker = options['a'] unless options['a'].nil?
  testdir = options['t'] unless options['t'].nil?

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
