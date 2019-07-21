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

module VulenvReport
  private

  def report_os_and_vul_software(report_file, vulenv_config)
    if vulenv_config['construction'].key?('vul_software')
      report_file.puts("### Vulnerable Software\n")
      report_file.puts("#{vulenv_config['construction']['vul_software']['name']} : #{vulenv_config['construction']['vul_software']['version']}\n")
    end
    report_file.puts("\n")

    if vulenv_config['construction']['os']['vulnerability'] then report_file.puts("### Vulnerable Software\n")
    else report_file.puts("### Operating System\n")
    end
    report_file.puts("#{vulenv_config['construction']['os']['name']} : #{vulenv_config['construction']['os']['version']}")
    report_file.puts("\n")
  end

  def report_related_software(report_file, vulenv_config)
    if vulenv_config['construction'].key?('related_software')
      report_file.puts('### Related Software')
      vulenv_config['construction']['related_software'].each { |software| report_file.puts("- #{software['name']} : #{software['version']}\n") }
    end
    report_file.puts("\n")
  end
end
