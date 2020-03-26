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
require 'tty-prompt'

require './app/app'
require './app/command/test_command'
require './app/command/destroy_command'
require './app/command/exploit_command'
require './app/command/report_command'
require './app/command/set_command'

class Console < App
  attr_reader :prompt, :name

  def initialize
    super
    @prompt = TTY::Prompt.new(active_color: :cyan, help_color: :bright_white, track_history: true)
    @name = 'vultest'
  end

  def execute
    loop do
      cmd = prompt.ask("#{name} >")
      cmd.nil? ? next : cmd = cmd.split(' ')

      case cmd[0]
      when /test/i then test_command(cmd[1])
      when /destroy/i then destroy_command
      when /exploit/i then exploit_command
      when /report/i then report_command
      when /set/i then set_command(cmd[1], cmd[2])
      when /back/i then back_command
      when /exit/i then break
      else prompt.error("vultest: command not found: #{cmd[0]}")
      end
    end
  end

  private

  def test_command(cve)
    cmd = TestCommand.new(cve: cve, vultest_case: vultest_case, control_vulenv: control_vulenv, vulenv_dir: setting[:test_dir])

    cmd.execute
    @name = cmd.cve.nil? ? 'vultest' : cmd.cve
    @vultest_case = cmd.vultest_case
    @control_vulenv = cmd.control_vulenv
  end

  def destroy_command
    return if prompt.no?('Delete vulnerable environment?')

    cmd = DestroyCommand.new(control_vulenv: control_vulenv)
    cmd.execute { @control_vulenv = nil }
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
    cmd.execute(set_attack_env_proc, set_attack_host_proc)
  end

  def report_command
    cmd = ReportCommand.new(control_vulenv: control_vulenv, attack_env: attack_env, report_dir: setting[:test_dir])
    cmd.execute
  end

  def set_command(type, value)
    cmd = SetCommand.new(control_vulenv: control_vulenv, attack_env: attack_env)
    cmd.execute(type, value) { |set_type, set_value| @setting[set_type] = set_value }
  end

  def back_command
    return if vultest_case.nil?

    return unless prompt.yes?("Finish the vultest for #{vultest_case.cve}")

    @name = 'vultest'
    @vultest_case = @control_vulenv = @attack_env = nil
  end
end
