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
require 'fileutils'
require 'tty-markdown'

require 'lib/report/title'
require 'lib/report/vulenv'
require 'lib/report/attack'
require 'lib/report/vulnerability'

require 'lib/db'
require 'lib/print'

module Report
  REPORT_TITLE_TEMPLATE_PATH = './resources/report/title.md.erb'.freeze
  REPORT_VULENV_TEMPLATE_PATH = './resources/report/vulenv.md.erb'.freeze
  REPORT_ATTACK_TEMPLATE_PATH = './resources/report/attack.md.erb'.freeze
  REPORT_VULNERABILITY_TEMPLATE_PATH = './resources/report/vulnerability.md.erb'.freeze
  REPORT_ERROR_TEMPLATE_PATH = './resources/report/error.md.erb'.freeze

  class Core
    def initialize(args)
      @report_dir = args[:report_dir]
      @vulenv = args[:vulenv]
      @attack = args.fetch(:attack, nil)
    end

    def create
      create_title_part
      create_vulenv_part
      create_attack_part unless @attack.nil?
      create_vulenrability_part
    end

    def show
      Print.stdout(
        TTY::Markdown.parse_file("#{@report_dir}/report.md")
      )
    end

    private

    def create_title_part
      error =
        if @vulenv.error? then 'vulenv'
        elsif !@attack.nil? && @attack.exec_error? then 'attack'
        end

      Title.new({ report_dir: @report_dir, error: error }).create

      create_error_part(error) unless error.nil?
    end

    def create_error_part(error_type)
      erb = ERB.new(File.read(REPORT_ERROR_TEMPLATE_PATH), trim_mode: 2)

      case error_type
      when 'vulenv'
        error_ansible_role = nil
        error_command = nil
        @vulenv.vagrant.error_msg.split("\n").each do |e|
          error_info = e.match(/^TASK \[(?<error_ansible_role>.*)\s:\s(?<error_command>.*)\].*/)
          if error_info
            error_ansible_role = error_info[:error_ansible_role]
            error_command = error_info[:error_command]
          end
        end

      when 'attack'
        error_method = @attack.attack_method.error[:name]
        error_method_settings = @attack.attack_method.error[:option]
      end

      File.open("#{@report_dir}/report.md", 'a+') { |f| f.puts(erb.result(binding)) }
    end

    def create_vulenv_part
      Vulenv.new({ report_dir: @report_dir, vulenv_structure: @vulenv.structure }).create
    end

    def create_attack_part
      Attack.new({ report_dir: @report_dir, attack: @attack }).create
    end

    def create_vulenrability_part
      Vulnerability.new({ report_dir: @report_dir, cve: @vulenv.env_config['cve'] }).create
    end
  end
end
