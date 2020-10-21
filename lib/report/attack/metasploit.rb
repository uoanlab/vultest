# Copyright [202] [University of Aizu]
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
require 'json'

module Report
  module Attack
    class Metasploit
      def initialize(args)
        @report_dir = args[:report_dir]
        @attack = args[:attack]
      end

      def create
        erb = ERB.new(
          File.read("#{REPORT_ATTACK_TEMPLATE_DIR_PATH}/metasploit.md.erb"),
          trim_mode: 2
        )

        data = create_data
        File.open("#{@report_dir}/report.md", 'a+') { |f| f.puts(erb.result(binding)) }
      end

      private

      def create_data
        attack_methods = @attack.test_case.attack_config['metasploit'].map do |attack_method|
          attack_method['options'].unshift(
            { 
              'name' => 'LHOST',
              'value' => @attack.host
            }
          )
          attack_method
        end

        {
          attack_methods: attack_methods
        }
      end
    end
  end
end
