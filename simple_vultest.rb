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
require 'optparse'
require 'tty-prompt'

require './lib/vultest_case'
require './lib/vulenv/vulenv'
require './lib/attack/attack_env'
require './lib/report/vultest_report'
require './lib/ui'

opts = ARGV.getopts('', 'cve:', 'test:yes', 'attack_user:', 'attack_passwd:', 'attack_host:', 'dir:', 'destroy:no')

if opts['cve'].nil?
  VultestUI.error('Input CVE')
  return
end

cve = opts['cve']

setting = { test_dir: './test_dir', attack_host: nil, attack_user: 'root', attack_passwd: 'toor' }
setting[:test_dir] = opts['dir'] unless opts['dir'].nil?
setting[:attack_host] = opts['attack_host'] unless opts['attack_host'].nil?
setting[:attack_user] = opts['attack_user'] unless opts['attack_user'].nil?
setting [:attack_passwd] = opts['attack_passwd'] unless opts['attack_passwd'].nil?

# Process Vulteat Case
vultest_case = VultestCase.new(cve: cve)
return unless vultest_case.select_test_case?

if vultest_case.vulenv_config['attack_vector'] == 'local'
  setting[:attack_host] = '192.168.177.177'
  VultestUI.execute('Change value of ATTACKHOST')
elsif vultest_case.vulenv_config['attack_vector'] == 'remote' && setting[:attack_host].nil?
  VultestUI.error('Set value of ATTACKHOST')
  return
end

# Process Vulenv
vulenv = Vulenv.new(
  cve: vultest_case.cve,
  config: vultest_case.config,
  vulenv_config: vultest_case.vulenv_config,
  vulenv_dir: setting[:test_dir]
)

if vulenv.create?
  vulenv.output_manually_setting if vulenv.vulenv_config['construction'].key?('prepare')
else
  vulenv.error[:flag] = true
  VultestReport.new(
    vultest_case: vultest_case,
    vulenv: vulenv,
    report_dir: setting[:test_dir]
  ).create_report

  return
end

return if opts['test'] == 'no'

# Process Attack
TTY::Prompt.new.keypress('If you start the attack, puress ENTER key', keys: [:return])
attack_env = AttackEnv.new(
  attack_host: setting[:attack_host],
  attack_user: setting[:attack_user],
  attack_passwd: setting[:attack_passwd],
  attack_vector: vultest_case.vulenv_config['attack_vector']
)

unless attack_env.execute_attack?(vultest_case.attack_config['metasploit_module'])
  VultestReport.new(
    vultest_case: vultest_case,
    vulenv: vulenv,
    attack_env: attack_env,
    report_dir: setting[:test_dir]
  ).create_report

  return
end

# Process Vultest Report
VultestReport.new(
  vultest_case: vultest_case,
  vulenv: vulenv,
  attack_env: attack_env,
  report_dir: setting[:test_dir]
).create_report

attack_env.rob_shell

if opts['destroy'] == 'yes'
  vulenv.destroy!
  VultestUI.execute("Delete the vulnerable environment for #{vulenv.cve}")
end
