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

require_relative '../process/vultest'
require_relative './lib/option_set'

class VultestConsole
  attr_reader :prompt, :prompt_name

  include OptionSet

  def initialize
    font = TTY::Font.new(:"3d")
    pastel = Pastel.new
    puts pastel.red(font.write('VULTEST'))
  end

  def initialize_prompt
    @prompt = TTY::Prompt.new(active_color: :cyan, help_color: :bright_white, track_history: true)
    @prompt_name = 'vultest'
  end

  def initialize_vultest_processing
    @vultest_processing = ProcessVultest.new
  end

  def execute_test_command(args)
    unless args[:cve] =~ /^(CVE|cve)-\d+\d+/i
      @prompt.error('The CVE entered is incorrect')
      return
    end

    unless @vultest_processing.cve.nil?
      @prompt.error('Cannot run multiple vulnerable tests at the same time')
      @prompt.error("Running the vulnerable test for #{@vultest_processing.cve}")
      return
    end

    @vultest_processing.start_vultest(args[:cve])
    @prompt_name = @vultest_processing.cve unless @vultest_processing.cve.nil?
  end

  def execute_exploit_command
    if @vultest_processing.cve.nil?
      @prompt.error('Not during the execution of vulnerable test')
      return
    end
    @vultest_processing.start_attack
  end

  def execute_option_command(args)
    if args[:option_type].nil? || args[:option_value].nil?
      @prompt.error('The usage of set command is incorrect')
      return
    end

    case args[:option_type]
    when /testdir/i then configure_testdir(args[:option_value])
    when /attackhost/i then configure_attack_host(args[:option_value])
    when /attackuser/i then configure_attack_user(args[:option_value])
    when /attackpasswd/i then configure_attack_passwd(args[:option_value])
    else @prompt.error("Invalid option (#{args[:option_type]})")
    end
  end

  def execute_report_command
    @vultest_processing.execute_vultest_report
  end

  def execute_destroy_command
    @vultest_processing.destroy_vulenv! unless @prompt.no?('Delete vulnerable environment?')
  end

  def execute_back_command
    @prompt_name = 'vultest'
    @vultest_processing = ProcessVultest.new
  end

  private

  def configure_testdir(dir)
    unless @vultest_processing.cve.nil?
      @prompt.error('Cannot change a environment of test in a vulnerable test')
      return
    end
    @vultest_processing.test_dir = create_vulenv_dir(dir)
    @prompt.ok("TESTDIR => #{@vultest_processing.test_dir}")
  end

  def configure_attack_host(host)
    if connection_attack_host?
      @prompt.error('Cannot change the attack host in attack')
      return
    end
    @vultest_processing.attack[:host] = host
    @prompt.ok("ATTACKHOST => #{@vultest_processing.attack[:host]}")
  end

  def configure_attack_user(user)
    if connection_attack_host?
      @prompt.error('Cannot change the attack user in attack')
      return
    end
    @vultest_processing.attack[:user] = user
    @prompt.ok("ATTACKUSER => #{@vultest_processing.attack[:user]}")
  end

  def configure_attack_passwd(passwd)
    if connection_attack_host?
      @prompt.error('Cannot change the password of attack user in attack')
      return
    end
    @vultest_processing.attack[:passwd] = passwd
    @prompt.ok("ATTACKPASSWD => #{@vultest_processing.attack[:passwd]}")
  end

  def connection_attack_host?
    return false if @vultest_processing.exploit.nil?

    return false if @vultest_processing.exploit.msf_api.nil?

    true
  end
end
