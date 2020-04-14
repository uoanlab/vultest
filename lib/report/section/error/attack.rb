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

require './lib/report/section/error/base'

module Report
  module Section
    module Error
      class Attack < Base
        attr_reader :attack_env

        def initialize(args)
          @attack_env = args[:attack_env]
        end

        private

        def error_section
          section = "#### Module Name : #{attack_env.operating_environment.attack.error[:module_name]}\n"
          attack_env.operating_environment.attack.error[:module_option].each { |key, value| section << "- #{key} : #{value}\n" }
          section << "\n\n"
        end
      end
    end
  end
end
