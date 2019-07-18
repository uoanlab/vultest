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

require_relative './process/vultest'

class VultestConsole
  attr_reader :prompt, :prompt_name

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
    @vultest_processing.attack_vulenv
  end

  def execute_option_command(args)
    if args[:option_type] =~ /testdir/i
      option_testdir(dir: args[:option_value])
    elsif args[:option_type] =~ /attackhost/i
      @vultest_processing.attack[:host] = args[:option_value]
      @prompt.ok("ATTACKHOST => #{@vultest_processing.attack[:host]}")
    elsif args[:option_type] =~ /attackuser/i
      @vultest_processing.attack[:user] = args[:option_value]
      @prompt.ok("ATTACKERUSER => #{@vultest_processing.attack[:user]}")
    elsif args[:option_type] =~ /attackpasswd/i
      @vultest_processing.attack[:passwd] = args[:option_value]
      @prompt.ok("ATTACKPASSWD => #{@vultest_processing.attack[:passwd]}")
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

  def option_testdir(args)
    unless @vultest_processing.cve.nil?
      @prompt.error('Cannot execute set command after you executed test command')
      return
    end

    path = ''
    path_elm = args[:dir].split('/')

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
    @prompt.ok("TESTDIR => #{@vultest_processing.test_dir}")
  end
end
