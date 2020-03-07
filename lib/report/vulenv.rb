# Copyright [2019] [University of Aizu]
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

require 'json'

module VulenvReport
  private

  def write_vulenv_report(report_file)
    report_file.puts("## Target Host\n\n")
    write_vul_software(report_file) if vulenv.vulenv_config['construction'].key?('vul_software')
    write_os(report_file)
    write_related_software(report_file) if vulenv.vulenv_config['construction'].key?('related_software')
    return if vulenv.error[:flag]

    write_port_list(report_file)
    write_service_list(report_file)
  end

  def write_vul_software(report_file)
    report_file.puts("### Vulnerable Software\n")
    report_file.puts("#{vulenv.vulenv_config['construction']['vul_software']['name']} : #{vulenv.vulenv_config['construction']['vul_software']['version']}\n")
    report_file.puts("\n")
  end

  def write_os(report_file)
    vulenv.vulenv_config['construction']['os']['vulnerability'] ? report_file.puts("### Vulnerable Software\n") : report_file.puts("### Operating System\n")
    report_file.puts("#{vulenv.vulenv_config['construction']['os']['name']} : #{vulenv.vulenv_config['construction']['os']['version']}")
    report_file.puts("\n")
  end

  def write_related_software(report_file)
    report_file.puts('### Related Software')
    vulenv.vulenv_config['construction']['related_software'].each { |software| report_file.puts("- #{software['name']} : #{software['version']}\n") }
    report_file.puts("\n")
  end

  def write_port_list(report_file)
    report_file.puts('### Port')

    socket_list = case vulenv.vulenv_config['construction']['os']['name']
                  when 'windows' then vulenv.port_list_in_windows
                  else vulenv.port_list_in_linux
                  end
    socket_list.each do |socket|
      output = socket[:port] == socket[:service] ? "- #{socket[:port]}/#{socket[:protocol]}" : "- #{socket[:port]}/#{socket[:protocol]}(#{socket[:service]})"
      report_file.puts(output)
    end
    report_file.puts("\n")
  end

  def write_service_list(report_file)
    report_file.puts('### Service')

    case vulenv.vulenv_config['construction']['os']['name']
    when 'windows'
      stdout, cmd = vulenv.service_list_in_windows
      service = stdout.gsub(/\s+\n/, "\n").gsub('-', '=')
    else service, cmd = vulenv.service_list_in_linux
    end

    report_file.puts("- Command: #{cmd}")
    report_file.puts(service)
    report_file.puts("\n")
  end

  def write_error_of_vulenv(report_file)
    report_file.puts("## Root Cause\n\n")
    msg_of_cause = vulenv.error[:cause].split("\n")
    error = {}

    msg_of_cause.each do |e|
      error_software = e.match(/^TASK \[(?<software>.*)\s:\s(?<install_method>.*)\].*/)
      if error_software
        error[:software_path] = error_software[:software]
        error[:software_install_method] = error_software[:install_method]
      end

      error[:msg] = e.match(/^fatal: .*/).to_s
      next if error[:msg].empty?

      error[:msg] = JSON.parse(e.match(/\{.*\}/).to_s)

      report_file.puts("### Software Name : #{error[:software_path].split('/')[2]}\n\n")
      report_file.puts("### Install Method : #{error[:software_install_method]}\n\n")
      report_file.puts("### Error Message (Ansible Message)\n")
      error[:msg].each { |key, value| report_file.puts("- #{key} => #{value}\n") }
      error = {}
    end

    report_file.puts("\n")
  end
end
