require 'bundler/setup'
require 'pastel'
require 'tty-font'

require_relative './process/vultest'
require_relative './ui'

class VultestConsole
  attr_reader :prompt

  def initialize
    font = TTY::Font.new(:"3d")
    pastel = Pastel.new
    puts pastel.red(font.write('VULTEST'))

    @prompt = 'vultest'
    @vultest_processing = ProcessVultest.new
  end

  def test_command(cve)
    @vultest_processing.create_vulenv(cve)
    @prompt = @vultest_processing.cve unless @vultest_processing.cve.nil?
  end

  def exploit_command
    @vultest_processing.attack_vulenv
  end

  def option_command(command)
    if command.length != 3
      VultestUI.print_vultest_message('error', 'Inadequate option')
      return
    end

    if command[1] =~ /testdir/i
      option_testdir(command[2])
    elsif command[1] =~ /attackhost/i
      @vultest_processing.attack[:host] = command[2]
      puts("ATTACKHOST => #{@vultest_processing.attack[:host]}")
    elsif command[1] =~ /attackuser/i
      @vultest_processing.attack[:user] = command[2]
      puts("ATTACKERUSER => #{@vultest_processing.attack[:user]}")
    elsif command[1] =~ /attackpasswd/i
      @vultest_processing.attack[:passwd] = command[2]
      puts("ATTACKPASSWD => #{@vultest_processing.attack[:passwd]}")
    else puts("Not fund option (#{command[1]})")
    end
  end

  def report_command
    @vultest_processing.execute_vultest_report
  end

  def destroy_command
    @vultest_processing.destroy_vulenv!
  end

  private

  def option_testdir(option_value)
    unless @vultest_processing.cve.nil?
      VultestUI.print_vultest_message('error', 'Cannot execute set command')
      return
    end

    path = ''
    path_elm = option_value.split('/')

    path_elm.each do |elm|
      path.concat('/') unless path.empty?
      if elm[0] == '$'
        elm.slice!(0)
        ENV.key?(elm) ? path.concat(ENV[elm]) : path.concat(elm)
      else
        path.concat(elm)
      end
    end
    @vultest_processing.test_dir = path
    puts("TESTDIR => #{@vultest_processing.test_dir}")
  end
end
