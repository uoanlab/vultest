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

require './cmd/command'
require './modules/ui'

puts Pastel.new.red(TTY::Font.new(:"3d").write('VULTEST'))
console = {}
console[:prompt] = TTY::Prompt.new(active_color: :cyan, help_color: :bright_white, track_history: true)
console[:name] = 'vultest'

setting = {}
setting[:test_dir] = ENV.fetch('TESTDIR', './test_dir')
setting[:attack_host] = ENV.fetch('ATTACKHOST', nil)
setting[:attack_user] = ENV.fetch('ATTACKERUSER', 'root')
setting [:attack_passwd] = ENV.fetch('ATTACKPASSWD', 'toor')

vultest_case = nil
vulenv = nil
attack_env = nil

loop do
  cmd = console[:prompt].ask("#{console[:name]} >")
  cmd.nil? ? next : cmd = cmd.split(' ')

  case cmd[0]
  when /test/i
    console[:name], vultest_case, vulenv = Command.test(
      cve: cmd[1],
      vultest_case: vultest_case,
      vulenv_dir: setting[:test_dir]
    )

  when /destroy/i
    vulenv = Command.destroy(prompt: console[:prompt], vulenv: vulenv)

  when /exploit/i
    if vultest_case.vulenv_config['attack_vector'] == 'local'
      setting[:attack_host] = '192.168.177.177'
      VultestUI.execute('Change value of ATTACKHOST')
      console[:prompt].ok('ATTACKHOST => 192.168.177.177')
    elsif vultest_case.vulenv_config['attack_vector'] == 'remote' && setting[:attack_host].nil?
      VultestUI.error('Cannot find the attack host')
      VultestUI.warring('Execute : SET ATTACKHOST attack_host_ip_address')
      next
    end

    attack_env = Command.exploit(
      vultest_case: vultest_case,
      vulenv: vulenv,
      attack_host: setting[:attack_host],
      attack_user: setting[:attack_user],
      attack_passwd: setting[:attack_passwd]
    )

  when /report/i
    Command.report(
      vultest_case: vultest_case,
      vulenv: vulenv,
      attack_env: attack_env,
      report_dir: setting[:test_dir]
    )

    next if vulenv.error[:flag] || attack_env.nil? || attack_env.error[:flag]

    attack_env.rob_shell

  when /set/i
    Command.set(
      prompt: console[:prompt],
      setting: setting,
      vulenv: vulenv,
      attack_env: attack_env,
      type: cmd[1],
      value: cmd[2]
    )

  when /back/i
    console[:name], vultest_case, vulenv, attack_env = Command.back(
      prompt: console[:prompt],
      name: console[:name],
      vultest_case: vultest_case,
      vulenv: vulenv,
      attack_env: attack_env
    )

  when /exit/i then break
  else console[:prompt].error("vultest: command not found: #{cmd[0]}")
  end
end
