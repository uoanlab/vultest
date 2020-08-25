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
require 'json'
require 'tty-markdown'

require 'lib/db'
require 'lib/print'

class Report
  REPORT_TITLE_TEMPLATE_PATH = './resources/report/title.md.erb'.freeze
  REPORT_VULENV_TEMPLATE_PATH = './resources/report/vulenv.md.erb'.freeze
  REPORT_ATTACK_TEMPLATE_PATH = './resources/report/attack.md.erb'.freeze
  REPORT_VULNERABILITY_TEMPLATE_PATH = './resources/report/vulnerability.md.erb'.freeze
  REPORT_ERROR_TEMPLATE_PATH = './resources/report/error.md.erb'.freeze

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
    erb = ERB.new(File.read(REPORT_TITLE_TEMPLATE_PATH), trim_mode: 2)

    error_type = nil
    if @vulenv.error?
      error_type = 'vulenv'
    elsif !@attack.nil?
      error_type = 'attack' if @attack.exec_error?
    end

    File.open("#{@report_dir}/report.md", 'w') { |f| f.puts(erb.result(binding)) }

    create_error_part(error_type) unless error_type.nil?
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
      error_method = @attack.attack_tool.error[:name]
      error_method_settings = @attack.attack_tool.error[:option]
    end

    File.open("#{@report_dir}/report.md", 'a+') { |f| f.puts(erb.result(binding)) }
  end

  def create_vulenv_part
    erb = ERB.new(File.read(REPORT_VULENV_TEMPLATE_PATH), trim_mode: 2)

    structure = @vulenv.structure
    os = structure[:os]
    vul_software = structure[:vul_software]
    related_softwares = structure[:related_softwares]
    ipadders = structure[:ipadders]
    port_list = structure[:port_list]
    services = structure[:services]

    File.open("#{@report_dir}/report.md", 'a+') { |f| f.puts(erb.result(binding)) }
  end

  def create_attack_part
    erb = ERB.new(File.read(REPORT_ATTACK_TEMPLATE_PATH), trim_mode: 2)

    attack_tool = nil
    attack_methods = []

    if @attack.attack_tool.instance_of?(::Attack::Tool::Metasploit)
      attack_tool = 'Metasploit'
      attack_methods = @attack.attack_config['metasploit']
    elsif @attack.attack_tool.instance_of?(::Attack::Tool::HTTP)
      attack_tool = 'HTTP'
      target_url = @attack.attack_tool.target_url
      attack_url = @attack.attack_tool.attack_request_setting[:url]
      attack_http_method = @attack.attack_tool.attack_request_setting[:method]
      request_header = @attack.attack_tool.request[:header]
      request_body = @attack.attack_tool.request[:body]
      response_header = @attack.attack_tool.response[:header]
      response_body = JSON.pretty_generate(JSON.parse(@attack.attack_tool.response[:body]))
    end

    File.open("#{@report_dir}/report.md", 'a+') { |f| f.puts(erb.result(binding)) }
  end

  def create_vulenrability_part
    erb = ERB.new(File.read(REPORT_VULNERABILITY_TEMPLATE_PATH), trim_mode: 2)

    cve = @vulenv.env_config['cve']

    cve_description = ''
    cve_info = DB.get_cve_info(cve)
    unless cve_info['description'].nil?
      sentence = ''
      cve_info['description'].split(' ') do |str|
        sentence += sentence.empty? ? str : " #{str}"

        next if sentence.size < 100

        cve_description += "> #{sentence}\n"
        sentence = ''
      end
      cve_description += "> #{sentence}\n" unless sentence.empty?
    end

    cpes = []
    cpe = DB.get_cpe(cve)
    cpe.each do |cpe_info|
      output_cpe_info = ''
      cpe_info.each_char { |c| output_cpe_info += c == '*' ? "\\#{c}" : c }
      cpes.push(output_cpe_info)
    end

    File.open("#{@report_dir}/report.md", 'a+') { |f| f.puts(erb.result(binding)) }
  end
end
