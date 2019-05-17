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

require_relative '../attack/exploit'
require_relative '../env/vulenv'
require_relative '../report/vultest_report'
require_relative '../utility'

module TestCommand
  def exploit(attacker, testdir, vulenv_config_path, attack_config_path)
    if attack_config_path.nil? 
      Utility.print_message('error', 'Cannot search exploit configure')
      return nil
    end

    vulenv_config = YAML.load_file(vulenv_config_path)
    if vulenv_config['attack_vector'] != 'remote'
      attacker = '192.168.33.10'
    end

    if attacker.nil?
      Utility.print_message('error', 'Set attack machin ip address')
      return nil
    end

    Exploit.prepare(attacker, testdir, vulenv_config_path) if vulenv_config['attack_vector'] == 'remote'
    Exploit.exploit(attacker, attack_config_path)

  end

  def set(option, var)
    if option == 'TESTDIR'
      path = ''
      path_elm = var.split("/")

      path_elm.each do |elm|
        path.concat('/') unless path.empty?
        if elm[0] == '$'
          elm.slice!(0)
          if ENV.key?(elm)
            path.concat(ENV[elm])
          else
            path.concat(elm)
          end
        else
          path.concat(elm)
        end
      end

      return path
    end

    return var
  end

  def report(cve, testdir, vulenv_config_path, attack_config_path)
    if cve.nil?
      Utility.print_message('error', 'You have to set CVE.')
      return 'error'
    end

    if vulenv_config_path.nil?
      Utility.print_message('error', 'Cannot have vulnerable environmently configure')
    end

    VultestReport.report(cve, testdir, vulenv_config_path, attack_config_path)
    Exploit.verify
  end

  def destroy(vulenv_dir)
    Vulenv.destroy(vulenv_dir)
  end

  module_function :exploit
  module_function :set
  module_function :report
  module_function :destroy
end
