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

class VultestReport
  include AttackReport
  include CVEReport
  include VulenvReport

  def initialize(args = {})
    @cve = args[:cve]
    @report_dir = args[:report_dir]
    @vulenv_config = args[:vulenv_config]
    @attack_config = args[:attack_config]
  end

  def create_report
    File.open("#{@report_dir}/report.md", 'w') do |report_file|
      report_file.puts("# Vultest Report\n\n")
      report_file.puts("## Target Host\n\n")
      report_os_and_vul_software(report_file, @vulenv_config)
      report_related_software(report_file, @vulenv_config)
      report_attack_method(report_file, @attack_config)
      report_cve_description(report_file, @cve)
      report_cpe(report_file, @cve)
    end

    parsed = TTY::Markdown.parse_file("#{@report_dir}/report.md")
    puts parsed
  end
end
