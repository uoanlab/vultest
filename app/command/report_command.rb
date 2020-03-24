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

require './app/command/command'
require './lib/report/vultest_report'
require './modules/ui'

class ReportCommand < Command
  attr_reader :control_vulenv, :attack_env, :report_dir
  def initialize(args)
    @control_vulenv = args[:control_vulenv]
    @attack_env = args[:attack_env]
    @report_dir = args[:report_dir]
  end

  def execute
    if control_vulenv.nil?
      VultestUI.error('There is no a vulnerable environment')
      return
    end

    if attack_env.nil? && !control_vulenv.error[:flag]
      VultestUI.error('Execute exploit command')
      return
    end

    vultest_report = prepare_vultest_report
    vultest_report.create_report
  end

  private

  def prepare_vultest_report
    VultestReport.new(control_vulenv: control_vulenv, attack_env: attack_env, report_dir: report_dir)
  end
end
