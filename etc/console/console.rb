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
require 'pastel'
require 'tty-font'
require 'tty-prompt'

require_relative '../../proc/vultest'
require_relative './option'

class Console
  attr_reader :prompt
  attr_accessor :prompt_name

  include Option

  def initialize
    font = TTY::Font.new(:"3d")
    pastel = Pastel.new
    puts pastel.red(font.write('VULTEST'))
  end

  def initialize_prompt
    @prompt = TTY::Prompt.new(active_color: :cyan, help_color: :bright_white, track_history: true)
    @prompt_name = 'vultest'
  end

  def initialize_vultest_process
    @process = ProcessVultest.new
  end

  def execute_test_command(args)
    during_vultest?(false, 'Cannot run multiple vulnerable tests at the same time') do
      @process.start_vultest(args[:cve])
      @prompt_name = @process.cve unless @process.cve.nil?
    end
  end

  def execute_exploit_command
    during_vultest? { @process.start_attack }
  end

  def execute_option_command(args)
    if args[:option_type].nil? || args[:option_value].nil?
      @prompt.error('The usage of set command is incorrect')
      return
    end

    case args[:option_type]
    when /testdir/i then configure_testdir(args[:option_value])
    when /attackhost/i then configure_attack(args[:option_type], args[:option_value]) { @process.attacker[:host] = args[:option_value] }
    when /attackuser/i then configure_attack(args[:option_type], args[:option_value]) { @process.attacker[:user] = args[:option_value] }
    when /attackpasswd/i then configure_attack(args[:option_type], args[:option_value]) { @process.attacker[:passwd] = args[:option_value] }
    else @prompt.error("Invalid option (#{args[:option_type]})")
    end
  end

  def execute_report_command
    during_vultest? { @process.start_vultest_report }
  end

  def execute_destroy_command
    during_vultest? { @process.destroy_vulenv! unless @prompt.no?('Delete vulnerable environment?') }
  end

  def execute_back_command
    @prompt.yes?("Finish the vultest for #{@cve}")
  end

  private

  def configure_testdir(dir)
    during_vultest?(false, 'Cannot change a environment of test in a vulnerable test') do
      @process.test_dir = create_vulenv_dir(dir)
      @prompt.ok("TESTDIR => #{@process.test_dir}")
    end
  end

  def configure_attack(option, value, &block)
    if @process.connection_attack_host?
      @prompt.error('Cannot change the attack option in attack')
      return
    end
    block.call
    @prompt.ok("#{option} => #{value}")
  end

  def during_vultest?(flag = true, msg = 'Not during the execution of vulnerable test', &block)
    if flag && @process.cve.nil?
      @prompt.error(msg)
      return
    end

    unless flag || @process.cve.nil?
      @prompt.error(msg)
      return
    end

    block.call
  end
end
