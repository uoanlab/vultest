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

module AttackReport
  private

  def report_attack_method(report_file, attack_config)
    report_file.puts("## Attack Method\n\n")
    if attack_config.key?('metasploit_module')
      report_file.puts("### Metasploit\n\n")
      attack_methods = attack_config['metasploit_module']
      attack_methods.each do |attack_method|
        report_file.puts("#### Module Name : #{attack_method['module_name']}\n")
        attack_method['options'].each { |option| report_file.puts("- #{option['name']} : #{option['var']}\n") }
        report_file.puts("\n")
      end
    end
    report_file.puts("\n")
  end
end
