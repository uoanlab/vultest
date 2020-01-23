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

require './lib/vultest_case'
require './lib/vulenv/vulenv'
require './lib/attack/attack_env'
require './lib/report/vultest_report'
require './lib/ui'
require './lib/util'

module Command
  class << self
    def test(args)
      cve = args.fetch(:cve, nil)
      vultest_case = args.fetch(:vultest_case, nil)
      vulenv_dir = args.fetch(:vulenv_dir, './test_dir')

      return 'vultest', nil, nil unless vultest_case.nil?

      unless cve =~ /^(CVE|cve)-\d+\d+/i
        VultestUI.error('The CVE entered is incorrect')
        return 'vultest', nil, nil
      end

      vultest_case = VultestCase.new(cve: cve)
      return 'vultest', nil, nil unless vultest_case.select_test_case?

      vulenv = Vulenv.new(
        cve: vultest_case.cve,
        config: vultest_case.config,
        vulenv_config: vultest_case.vulenv_config,
        vulenv_dir: vulenv_dir
      )

      if vulenv.create?
        vulenv.output_manually_setting if vulenv.vulenv_config['construction'].key?('prepare')
      else
        VultestUI.warring('Can look at a report about error in construction of vulnerable environment')
      end

      return cve, vultest_case, vulenv
    end

    def destroy(args)
      prompt = args[:prompt]
      vulenv = args.fetch(:vulenv, nil)

      if vulenv.nil?
        VultestUI.error('Doesn\'t exist a vulnerabule environment')
        return vulenv
      end
      return vulenv if prompt.no?('Delete vulnerable environment?')

      return vulenv unless vulenv.destroy!

      VultestUI.execute("Delete the vulnerable environment for #{vulenv.cve}")
      return nil
    end

    def exploit(args)
      vultest_case = args[:vultest_case]
      vulenv = args[:vulenv]
      attack_host = args[:attack_host]
      attack_user = args[:attack_user]
      attack_passwd = args[:attack_passwd]

      if vulenv.nil?
        VultestUI.error('There is not the vulnerable environment which is attack target')
        return nil
      end

      attack_env = AttackEnv.new(
        attack_host: attack_host,
        attack_user: attack_user,
        attack_passwd: attack_passwd,
        attack_vector: vultest_case.vulenv_config['attack_vector']
      )

      unless attack_env.execute_attack?(vultest_case.attack_config['metasploit_module'])
        VultestUI.warring('Can look at a report about error in attack execution')
      end

      return attack_env
    end

    def set(args)
      prompt = args[:prompt]
      setting = args[:setting]
      vulenv = args.fetch(:vulenv, nil)
      attack_env = args.fetch(:attack_env, nil)

      input = {}
      input[:type] = args.fetch(:type, nil)
      input[:value] = args.fetch(:value, nil)

      if input[:type].nil? || input[:value].nil?
        prompt.error('The usage of set command is incorrect')
        return
      end

      unless vulenv.nil? && attack_env.nil?
        prompt.error('Cannot change a setting in a vulnerable test')
        return
      end

      setting_set_value(setting, input[:type], input[:value]) ? prompt.ok("#{input[:type]} => #{input[:value]}") : prompt.error("Invalid option (#{type})")
    end

    def back(args)
      prompt = args[:prompt]
      console_name = args[:name]
      vultest_case = args[:vultest_case]
      vulenv = args[:vulenv]
      attack_env = args[:attack_env]

      if prompt.yes?("Finish the vultest for #{vultest_case.cve}")
        console_name = 'vultest'
        vultest_case = vulenv = attack_env = nil
      end

      return console_name, vultest_case, vulenv, attack_env
    end

    def report(args)
      vultest_case = args[:vultest_case]
      vulenv = args[:vulenv]
      attack_env = args[:attack_env]
      report_dir = args[:report_dir]

      if vulenv.nil?
        VultestUI.error('There is no a vulnerable environment')
        return
      end

      if attack_env.nil? && !vulenv.error[:flag]
        VultestUI.error('Execute exploit command')
        return
      end

      VultestReport.new(
        vultest_case: vultest_case,
        vulenv: vulenv,
        attack_env: attack_env,
        report_dir: report_dir
      ).create_report
    end

    def setting_set_value(setting, type, value)
      case type
      when /testdir/i then setting[:test_dir] = Util.create_dir(value)
      when /attackhost/i then setting[:attack_host] = value
      when /attackuser/i then setting[:attack_user] = value
      when /attackpasswd/i then setting[:attack_passwd] = value
      else return false
      end

      return true
    end
  end
end
