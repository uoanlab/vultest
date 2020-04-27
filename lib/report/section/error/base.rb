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
    module Error
      class Base < Report::Section::Base
        def create
          section = "## Root Cause\n\n"
          section << error_section
        end

        private

        def error_section
          raise NotImplementedError
        end
      end
    end
  end
end
