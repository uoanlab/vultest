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

require './app/command/base'
require './lib/report/vultest'
require './lib/report/error_vulenv'
require './lib/report/error_attack'
require './modules/ui'

module Command
  class Report < Base
    attr_reader :vulenv, :attack_env, :report_dir
    def initialize(args)
      @vulenv = args[:vulenv]
      @attack_env = args[:attack_env]
      @report_dir = args[:report_dir]
    end

    def execute
      if vulenv.nil?
        VultestUI.error('There is no a vulnerable environment')
        return
      end

      if attack_env.nil? && !vulenv.error[:flag]
        VultestUI.error('Execute exploit command')
        return
      end

      vultest_report = prepare_vultest_report
      vultest_report.show
    end

    private

    def prepare_vultest_report
      if vulenv.error[:flag] then ::Report::ErrorVulenv.new(vulenv: vulenv, report_dir: report_dir)
      elsif attack_env.operating_environment.attack.error[:flag] then ::Report::ErrorAttack.new(vulenv: vulenv, attack_env: attack_env, report_dir: report_dir)
      else ::Report::Vultest.new(vulenv: vulenv, attack_env: attack_env, report_dir: report_dir)
      end
    end
  end
end
