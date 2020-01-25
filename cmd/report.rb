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

require './lib/report/vultest_report'
require './lib/ui'

module Report
  def report(args)
    vultest_case = args[:vultest_case]
    vulenv = args[:vulenv]
    attack_env = args[:attack_env]
    report_dir = args[:report_dir]

    if vulenv.nil?
      VultestUI.error('There is no a vulnerable environment')
      return
    end

    if attack_env.nil? && !vulenv.error[:flag]
      VultestUI.error('Execute exploit command')
      return
    end

    VultestReport.new(
      vultest_case: vultest_case,
      vulenv: vulenv,
      attack_env: attack_env,
      report_dir: report_dir
    ).create_report
  end
end
