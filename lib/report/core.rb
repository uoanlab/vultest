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
  REPORT_TITLE_TEMPLATE_PATH = './resources/report/title.md.erb'.freeze
  REPORT_METADATA_TEMPLATE_PATH = './resources/report/metadata.md.erb'.freeze
  REPORT_HOST_TEMPLATE_PATH = './resources/report/host.md.erb'.freeze
  REPORT_VULNERABILITY_TEMPLATE_PATH = './resources/report/vulnerability.md.erb'.freeze
  REPORT_ERROR_TEMPLATE_PATH = './resources/report/error.md.erb'.freeze

  class Core
    def initialize(args)
      @report_dir = args[:report_dir]
      @vulenv = args[:vulenv]
      @attack = args.fetch(:attack, nil)
      @test_case = args[:test_case]
    end

    def create
      create_title_part
      create_metadat_part
      create_vulenrability_part
      create_vulenv_part
      create_attack_part unless @attack.nil?
    end

    def show
      Print.stdout(
        TTY::Markdown.parse_file("#{@report_dir}/report.md")
      )
    end

    private

    def create_title_part
      Title.new(report_dir: @report_dir).create
    end

    def create_metadat_part
      Metadata.new(report_dir: @report_dir, test_case: @test_case).create
    end

    def create_vulenrability_part
      Vulnerability.new(
        report_dir: @report_dir,
        test_case: @test_case,
        vulenv: @vulenv
      ).create
    end

    def create_vulenv_part
      Host.new(report_dir: @report_dir, host: @vulenv.data).create
    end

    def create_attack_part
      case @attack.attack_method
      when 'metasploit'
        Metasploit.new(report_dir: @report_dir, attack: @attack).create
      when 'http'
        HTTP.new(report_dir: @report_dir, attack: @attack).create
      end
    end
  end
end
