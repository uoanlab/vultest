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
# limitations under the License

require './lib/vultest_case'
require './lib/vulenv/control_vulenv'
require './lib/attack/attack_env'
require './lib/report/vultest_report'
require './modules/ui'
require './modules/util'

module Command
  private

  def test?(cve)
    return false unless vultest_case.nil?

    unless cve =~ /^(CVE|cve)-\d+\d+/i
      VultestUI.error('The CVE entered is incorrect')
      return false
    end

    @vultest_case = VultestCase.new(cve: cve)
    return false unless vultest_case.select_test_case?

    @control_vulenv = ControlVulenv.new(
      cve: vultest_case.cve,
      config: vultest_case.config,
      vulenv_config: vultest_case.vulenv_config,
      vulenv_dir: setting[:test_dir]
    )

    VultestUI.warring('Can look at a report about error in construction of vulnerable environment') unless control_vulenv.create?
    true
  end

  def destroy?
    if control_vulenv.nil?
      VultestUI.error('Doesn\'t exist a vulnerabule environment')
      return false
    end

    return false unless control_vulenv.destroy?

    VultestUI.execute("Delete the vulnerable environment for #{control_vulenv.cve}")
    @control_vulenv = nil
    true
  end

  def exploit?
    if control_vulenv.nil?
      VultestUI.error('There is not the vulnerable environment which is attack target')
      return false
    end

    return false unless prepare_attack_host?

    @attack_env = AttackEnv.new(
      attack_host: setting[:attack_host],
      attack_user: setting[:attack_user],
      attack_passwd: setting[:attack_passwd],
      attack_config: vultest_case.attack_config,
      attack_vector: vultest_case.vulenv_config['attack_vector']
    )
    attack_env.execute_attack?
  end

  def prepare_attack_host?
    if vultest_case.vulenv_config['attack_vector'] == 'local'
      @setting[:attack_host] = '192.168.177.177'
      VultestUI.execute('Change value of ATTACKHOST')
      VultestUI.execute('ATTACKHOST => 192.168.177.177')
    elsif vultest_case.vulenv_config['attack_vector'] == 'remote' && setting[:attack_host].nil?
      VultestUI.error('Cannot find the attack host')
      VultestUI.warring('Execute : SET ATTACKHOST attack_host_ip_address')
      return false
    end

    true
  end

  def report?
    if control_vulenv.nil?
      VultestUI.error('There is no a vulnerable environment')
      return false
    end

    if attack_env.nil? && !control_vulenv.error[:flag]
      VultestUI.error('Execute exploit command')
      return
    end

    VultestReport.new(
      control_vulenv: control_vulenv,
      attack_env: attack_env,
      report_dir: setting[:test_dir]
    ).create_report
  end

  def set?(type, value)
    if type.nil? || value.nil?
      VultestUI.error('The usage of set command is incorrect')
      return false
    end

    unless control_vulenv.nil? && attack_env.nil?
      VultestUI.error('Cannot change a setting in a vulnerable test')
      return false
    end

    case type
    when /testdir/i then @setting[:test_dir] = Util.create_dir(value)
    when /attackhost/i then @setting[:attack_host] = value
    when /attackuser/i then @setting[:attack_user] = value
    when /attackpasswd/i then @setting[:attack_passwd] = value
    else
      VultestUI.error("Invalid option (#{type})")
      return false
    end

    VultestUI.execute("#{type} => #{value}")
    true
  end
end
