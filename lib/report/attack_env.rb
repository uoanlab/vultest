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

module AttackEnvReport
  private

  def write_attack_env_report(report_file)
    report_file.puts("## Attack Method\n\n")
    write_metasploit_module(report_file) if attack_env.attack_config.key?('metasploit')
  end

  def write_metasploit_module(report_file)
    attack_methods = attack_env.attack_config['metasploit']
    attack_methods.each do |attack_method|
      report_file.puts("#### Module Name : #{attack_method['module_name']}\n")
      attack_method['options'].each { |option| report_file.puts("- #{option['name']} : #{option['var']}\n") }
      report_file.puts("\n")
    end
    report_file.puts("\n")
  end

  def write_error_of_attack_env(report_file)
    report_file.puts("## Root Case\n\n")
    return unless attack_env.attack_config.key?('metasploit')

    report_file.puts("#### Module Name : #{attack_env.error[:module_name]}\n")
    attack_env.error[:module_option].each { |key, value| report_file.puts("- #{key} : #{value}\n") }
    report_file.puts("\n\n")
  end
end
