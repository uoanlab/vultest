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

require_relative '../db'
require_relative './attack'
require_relative './cve'
require_relative './vulenv'

module VultestReport
  include AttackReport
  include CVEReport
  include VulenvReport

  private

  def create_report(args = {})
    File.open("#{test_dir}/report.md", 'w') do |report_file|
      report_file.puts("# Vultest Report\n\n")
      report_target_host(report_file, args[:vulenv_config])
      report_attack_method(report_file, args[:attack_config])
      report_cve_description(report_file, args[:cve])
      report_cpe(report_file, args[:cve])
    end

    parsed = TTY::Markdown.parse_file("#{test_dir}/report.md")
    puts parsed
  end

  def report_target_host(report_file, vulenv_config)
    report_file.puts("## Target Host\n\n")
    report_os_and_vul_software(report_file, vulenv_config)
    report_related_software(report_file, vulenv_config)
  end
end
