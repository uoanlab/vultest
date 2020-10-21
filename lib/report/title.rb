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

module Report
  class Title < Base
    def initialize(args)
      super(report_dir: args[:report_dir], template_path: REPORT_TITLE_TEMPLATE_PATH)
    end

    def create
      FileUtils.touch("#{@report_dir}/report.md")
      super()
    end
    private

    def create_data
      {
        title: '# Vulnerability Test Report',
        date: Time.new,
        version: VERSION
      }
    end
  end
end
