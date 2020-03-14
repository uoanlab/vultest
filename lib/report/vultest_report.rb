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

require 'tty-markdown'

require './lib/report/vulenv'
require './lib/report/attack_env'
require './lib/report/vulnerability'

class VultestReport
  attr_reader :cve, :control_vulenv, :attack_env, :report_dir

  include VulenvReport
  include AttackEnvReport
  include VulnerabilityReport

  def initialize(args)
    @control_vulenv = args[:control_vulenv]
    @attack_env = args.fetch(:attack_env, nil)
    @report_dir = args[:report_dir]

    @cve = control_vulenv.cve
  end

  def create_report
    File.open("#{report_dir}/report.md", 'w') do |report_file|
      if control_vulenv.error[:flag]
        report_file.puts("# Vultest Report: Error in Construction of Vulnerable Environment\n\n")
        write_error_of_vulenv(report_file)
      elsif attack_env.error[:flag]
        report_file.puts("# Vultest Report: Error in Attack Execution\n\n")
        write_error_of_attack_env(report_file)
      else
        report_file.puts("# Vultest Report\n\n")
      end
      write_vulenv_report(report_file)
      write_attack_env_report(report_file) unless attack_env.nil?
      write_vulnerability_report(report_file)
    end

    puts TTY::Markdown.parse_file("#{@report_dir}/report.md")
  end
end
