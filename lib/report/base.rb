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

require 'bundler/setup'
require 'tty-markdown'

module Report
  class Base
    attr_reader :report_dir

    def initialize(report_dir)
      @report_dir = report_dir
    end

    def show
      create
      puts TTY::Markdown.parse_file("#{report_dir}/report.md")
    end

    private

    def create
      File.open("#{report_dir}/report.md", 'w') do |report_file|
        sections = report_details
        sections.each { |section| report_file.puts(section) }
      end
    end

    def report_details
      raise NotImplementedError
    end
  end
end
