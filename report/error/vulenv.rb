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

require_relative '../attack'
require_relative '../cve'
require_relative '../vulenv'

class ErrorVulenvReport
  include AttackReport
  include CVEReport
  include VulenvReport

  def initialize(args = {})
    @report_dir = args[:report_dir]
    @stderr = args[:stderr]
    @vulenv_config = args[:vulenv_config]
  end

  def create_report
    File.open("#{@report_dir}/error_vulenv_report.md", 'w') do |report_file|
      report_file.puts("# Error Report about Vulnerable Environment\n\n")
      report_file.puts("## Failuer Case\n\n")
      error_message_report(report_file, @stderr)

      report_file.puts("## Vulnerable Environment\n\n")
      report_os_and_vul_software(report_file, @vulenv_config)
      report_related_software(report_file, @vulenv_config)
    end

    parsed = TTY::Markdown.parse_file("#{@report_dir}/error_vulenv_report.md")
    puts parsed
  end

  private

  def error_message_report(report_file, stderr)
    stderr = stderr.split("\n")
    error = {}

    stderr.each do |e|
      error_software = e.match(/^TASK \[(?<software>.*)\s:\s(?<install_method>.*)\].*/)
      if error_software
        error[:software_path] = error_software[:software]
        error[:software_install_method] = error_software[:install_method]
      end

      error_msg = e.match(/^fatal:.*"stderr": "(?<err>.*)",\s"stderr_lines".*/)
      next unless error_msg

      error[:msg] = error_msg[:err].gsub(/(['"])/, '')

      report_file.puts("- software : #{error[:software_path].split('/')[2]}\n")
      report_file.puts("  - install method : #{error[:software_install_method]}\n")
      report_file.puts("  - msg : #{error[:msg]}\n")
      error = {}
    end

    report_file.puts("\n")
  end
end
