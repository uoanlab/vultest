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
  class Base
    def initialize(args)
      @report_dir = args[:report_dir]
      @template_path = args[:template_path]
    end

    def create
      erb = ERB.new(File.read(@template_path), trim_mode: 2)

      data = create_data
      File.open("#{@report_dir}/report.md", 'a+') { |f| f.puts(erb.result(binding)) }
    end

    private

    def create_data
      rais NotImplementedError
    end
  end
end
