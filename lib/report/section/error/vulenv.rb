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
# limitations under the License

require 'json'

require './lib/report/section/error/base'

module Report
  module Section
    module Error
      class Vulenv < Base
        attr_reader :control_vulenv

        def initialize(args)
          @control_vulenv = args[:control_vulenv]
        end

        private

        def error_section
          msg_of_cause = control_vulenv.error[:cause].split("\n")
          error = {}

          section = ''
          msg_of_cause.each do |e|
            error_software = e.match(/^TASK \[(?<software>.*)\s:\s(?<install_method>.*)\].*/)
            if error_software
              error[:software_path] = error_software[:software]
              error[:software_install_method] = error_software[:install_method]
            end

            error[:msg] = e.match(/^fatal: .*/).to_s
            next if error[:msg].empty?

            error[:msg] = JSON.parse(e.match(/\{.*\}/).to_s)

            section << "### Software Name : #{error[:software_path].split('/')[2]}\n\n"
            section << "### Install Method : #{error[:software_install_method]}\n\n"
            section << "### Error Message (Ansible Message)\n"
            error[:msg].each { |key, value| section << "- #{key} => #{value}\n" }
            error = {}
          end

          section << "\n"
        end
      end
    end
  end
end
