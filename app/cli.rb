# Copyright [2020] [University of Aizu]
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
require 'tty-prompt'

require './app/app'
require './app/command/test_command'
require './app/command/destroy_command'
require './app/command/exploit_command'
require './app/command/report_command'

require './modules/ui'

class CLI < App
  attr_reader :cve, :test_flag, :destroy_flag

  def initialize
    super
    opts = ARGV.getopts(
      '',
      'cve:',
      'test:yes',
      'attack_user:',
      'attack_passwd:',
      'attack_host:',
      'dir:',
      'destroy:no'
    )

    @cve = opts.fetch('cve', nil)
    @setting[:attack_host] = opts.fetch('attack_host', @setting[:attack_host])
    @setting[:attack_user] = opts.fetch('attack_user', @setting[:attack_user])
    @setting[:attack_passwd] = opts.fetch('attack_passwd', @setting[:attack_passwd])
    @setting[:test_dir] = opts.fetch('dir', @setting[:test_dir])
    @test_flag = opts['test']
    @destroy_flag = opts['destroy']
  end

  def execute
    if cve.nil?
      VultestUI.error('Input CVE')
      return
    end

    return unless create_vulenv?
    return if test_flag == 'no'

    TTY::Prompt.new.keypress('If you start the attack, puress ENTER key', keys: [:return])
    return unless exploit_vulenv?

    report_command
    destroy_command if destroy_flag == 'yes'
  end

  private

  def create_vulenv?
    test_command
    return false if vultest_case.nil? || control_vulenv.nil?

    if control_vulenv.error[:flag]
      report_command
      return false
    end

    true
  end

  def exploit_vulenv?
    exploit_command
    return false if attack_env.nil?

    if attack_env.error[:flag]
      report_command
      return false
    end

    true
  end

  def test_command
    cmd = TestCommand.new(cve: cve, vultest_case: vultest_case, control_vulenv: control_vulenv, vulenv_dir: setting[:test_dir])
    cmd.execute

    @vultest_case = cmd.vultest_case
    @control_vulenv = cmd.control_vulenv
  end

  def exploit_command
    cmd = ExploitCommand.new(
      vultest_case: vultest_case,
      control_vulenv: control_vulenv,
      attack_host: setting[:attack_host],
      attack_user: setting[:attack_user],
      attack_passwd: setting[:attack_passwd]
    )
    cmd.execute

    @setting[:attack_host] = cmd.attack_host
    @attack_env = cmd.attack_env
  end

  def report_command
    cmd = ReportCommand.new(control_vulenv: control_vulenv, attack_env: attack_env, report_dir: setting[:test_dir])
    cmd.execute
  end

  def destroy_command
    cmd = DestroyCommand.new(control_vulenv: control_vulenv)
    cmd.execute
    @control_vulenv = cmd.control_vulenv
  end
end
