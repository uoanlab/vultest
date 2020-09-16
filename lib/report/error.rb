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
require 'erb'

module Report
  class Error
    def initialize(args)
      @report_dir = args[:report_dir]
      @error = args[:error]
      @vulenv = args[:vulenv]
      @attack = args[:attack]
    end

    def create
      error_type = @error

      case error_type
      when 'vulenv' then create_vulenv(error_type)
      when 'attack' then create_attack(error_type)
      end
    end

    private

    def create_vulenv(error_type)
      erb = ERB.new(File.read(REPORT_ERROR_TEMPLATE_PATH), trim_mode: 2)

      error_ansible_role = nil
      error_command = nil
      @vulenv.vagrant.error_msg.split("\n").each do |e|
        error_info = e.match(/^TASK \[(?<error_ansible_role>.*)\s:\s(?<error_command>.*)\].*/)
        if error_info
          error_ansible_role = error_info[:error_ansible_role]
          error_command = error_info[:error_command]
        end
      end

      File.open("#{@report_dir}/report.md", 'a+') { |f| f.puts(erb.result(binding)) }
    end

    def create_attack(error_type)
      erb = ERB.new(File.read(REPORT_ERROR_TEMPLATE_PATH), trim_mode: 2)

      error_method = @attack.attack_method.error[:name]
      error_method_settings = @attack.attack_method.error[:option]

      File.open("#{@report_dir}/report.md", 'a+') { |f| f.puts(erb.result(binding)) }
    end
  end
end
