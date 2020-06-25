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

require 'lib/report/section/base'

module Report
  module Section
    class Attack < Base
      attr_reader :attack_env

      def initialize(args)
        @attack_env = args[:attack_env]
      end

      def create
        section = "## Attack Method\n\n"

        if attack_env.operating_environment.attack.instance_of?(::Attack::Metasploit)
          section << metasploit_modules_section
        elsif attack_env.operating_environment.attack.instance_of?(::Attack::HTTP)
          section << http_section
        end
      end

      private

      def metasploit_modules_section
        section = ''
        attack_methods = attack_env.operating_environment.attack.exploits
        attack_methods.each do |attack_method|
          section << "#### Module Name : #{attack_method['module_name']}\n"
          attack_method['options'].each { |option| section << "- #{option['name']} : #{option['var']}\n" }
          section << "\n"
        end
        section << "\n"
      end

      def http_section
        section = ''
        http_request = attack_env.operating_environment.attack.request

        section << "#### The URL used\n"
        section << http_request['url']
        section << "\n\n"

        section << "#### Method\n"
        section << http_request['method'].upcase
        section << "\n\n"

        if http_request.key?('headers')
          section << "#### Headers\n"
          http_request['headers'].each { |key, value| section << "- #{key} : #{value}\n" }
          section << "\n\n"
        end

        if http_request.key?('form_data')
          section << "#### Form Data\n"
          http_request['form_data'].each { |key, value| section << "- #{key} : #{value}\n" }
          section << "\n\n"
        end

        section << "\n"
      end
    end
  end
end
