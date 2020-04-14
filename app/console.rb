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
require './app/command/test'
require './app/command/destroy'
require './app/command/exploit'
require './app/command/report'
require './app/command/set'
require './modules/util'

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
      when /destroy/i then destroy_command(cmd[1])
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
    cmd = Command::Test.new(cve: cve, vultest_case: vultest_case, vulenv_dir: setting[:test_dir])

    cmd.execute do |value|
      @name = value[:cve]
      @vultest_case = value[:vultest_case]
      @vulenv = value[:vulenv]
    end
  end

  def destroy_command(env_name)
    if env_name.nil?
      VultestUI.error('Usage: destory <attack_env or vulenv>')
      return
    end

    env =
      case env_name
      when 'attack_env'
        return if !attack_env.is_a?(VM::AttackEnv::AutoRemoteHost) || prompt.no?('Delete the attack environment?')

        attack_env
      when 'vulenv'
        return if prompt.no?('Delete the vulnerable environment?')

        vulenv
      end

    cmd = Command::Destroy.new(env: env)
    cmd.execute do |value|
      case env_name
      when 'attack_env' then @attack_env = value[:env]
      when 'vulenv' then @vulenv = value[:env]
      end
    end
  end

  def exploit_command
    cmd = Command::Exploit.new(
      vultest_case: vultest_case,
      vulenv: vulenv,
      attack_host: setting[:attack_host],
      attack_user: setting[:attack_user],
      attack_passwd: setting[:attack_passwd],
      attack_dir: setting[:attack_dir]
    )

    cmd.execute do |value|
      @setting[:attack_host] = value[:attack_host]
      @attack_env = value[:attack_env]
    end
  end

  def report_command
    cmd = Command::Report.new(vulenv: vulenv, attack_env: attack_env, report_dir: setting[:test_dir])
    cmd.execute
  end

  def set_command(type, value)
    if type.nil? || value.nil?
      VultestUI.error('The usage of set command is incorrect')
      return
    end

    cmd = Command::Set.new(type: type, value: value, vulenv: vulenv, attack_env: attack_env)
    cmd.execute { |t, v| @setting[t] = v }
  end

  def back_command
    return if vultest_case.nil?

    return unless prompt.yes?("Finish the vultest for #{vultest_case.cve}")

    @name = 'vultest'
    @vultest_case = @vulenv = @attack_env = nil
  end
end
