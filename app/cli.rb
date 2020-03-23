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
require './app/command/set_command'

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

  def exec
    if cve.nil?
      VultestUI.error('Input CVE')
      return
    end

    test_command
    return if vultest_case.nil? || control_vulenv.nil?

    if control_vulenv.error[:flag]
      report_command
      return
    end

    return if test_flag == 'no'

    TTY::Prompt.new.keypress('If you start the attack, puress ENTER key', keys: [:return])
    exploit_command
    return if attack_env.nil?

    if attack_env.error[:flag]
      report_command
      return
    end

    report_command
    destroy_command if destroy_flag == 'yes'
  end

  private

  def test_command
    cmd = TestCommand.new(cve: cve, vultest_case: vultest_case, control_vulenv: control_vulenv, vulenv_dir: setting[:test_dir])

    set_proc = proc do |_set_name, set_vultest_case, set_control_vulenv|
      @vultest_case = set_vultest_case
      @control_vulenv = set_control_vulenv
    end

    cmd.exec(set_proc)
  end

  def exploit_command
    cmd = ExploitCommand.new(
      vultest_case: vultest_case,
      control_vulenv: control_vulenv,
      attack_host: setting[:attack_host],
      attack_user: setting[:attack_user],
      attack_passwd: setting[:attack_passwd]
    )

    set_attack_env_proc = proc { |set_attack_env| @attack_env = set_attack_env }
    set_attack_host_proc = proc { |set_attack_host| @setting[:attack_host] = set_attack_host }
    cmd.exec(set_attack_env_proc, set_attack_host_proc)
  end

  def report_command
    cmd = ReportCommand.new(control_vulenv: control_vulenv, attack_env: attack_env, report_dir: setting[:test_dir])
    cmd.exec
  end

  def destroy_command
    cmd = DestroyCommand.new(control_vulenv: control_vulenv)
    set_porc = proc { @control_vulenv = nil }
    cmd.exec(set_porc)
  end
end
