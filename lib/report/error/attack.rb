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

require 'tty-markdown'

require './lib/report/attack'
require './lib/report/cve'
require './lib/report/vulenv'

class ErrorAttackReport
  include AttackReport
  include CVEReport
  include VulenvReport

  def initialize(args = {})
    @report_dir = args[:report_dir]
    @vulenv_config = args[:vulenv_config]
    @attack_config = args[:attack_config]
  end

  def create_report(error_module)
    File.open("#{@report_dir}/error_attack_report.md", 'w') do |report_file|
      report_file.puts("# Vultest Report: Error in Attack Execution\n\n")
      error_attack_module_report(report_file, error_module)

      report_file.puts("## Target Host\n\n")
      report_os_and_vul_software(report_file, @vulenv_config)
      report_related_software(report_file, @vulenv_config)
    end

    parsed = TTY::Markdown.parse_file("#{@report_dir}/error_attack_report.md")
    puts parsed
  end

  private

  def error_attack_module_report(report_file, error_module)
    report_file.puts("## Root Cause\n\n")
    report_file.puts("### Metasploit\n\n")
    report_file.puts("####Module Name: #{error_module[:name]}\n")
    error_module[:option].each { |key, var| report_file.puts("- #{key} : #{var}\n\n") }
  end
end
