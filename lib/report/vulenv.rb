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
    status_vulenv = control_vulenv.status_vulenv

    report_file.puts("## Target Host\n\n")
    write_vul_software(report_file, status_vulenv)
    write_related_software(report_file, status_vulenv)

    write_ip_list(report_file, status_vulenv)
    write_port_list(report_file, status_vulenv)
    write_service_list(report_file, status_vulenv)
  end

  def write_vul_software(report_file, status_vulenv)
    report_file.puts("### Vulnerable Software\n")

    unless status_vulenv[:os][:vulnerability]
      report_file.puts("- #{status_vulenv[:vul_software][:name]} : #{status_vulenv[:vul_software][:version]}")
      report_file.puts("\n")
      report_file.puts("### Operating System\n")
    end

    write_os(report_file, status_vulenv)
  end

  def write_os(report_file, status_vulenv)
    report_file.puts("- Name: #{status_vulenv[:os][:name]}")
    report_file.puts("- Version: #{status_vulenv[:os][:version]}")

    unless status_vulenv[:base_version_of_os].nil?
      output = case status_vulenv[:os][:name]
               when 'windows' then '- Build Version: '
               else '- Kernel Version: '
               end
      output += status_vulenv[:base_version_of_os]
      report_file.puts(output)
    end
    report_file.puts("\n")
  end

  def write_related_software(report_file, status_vulenv)
    return if status_vulenv[:related_software].nil?

    report_file.puts('### Related Software')
    status_vulenv[:related_software].each { |software| report_file.puts("- #{software[:name]} : #{software[:version]}\n") }
    report_file.puts("\n")
  end

  def write_ip_list(report_file, status_vulenv)
    return unless status_vulenv.key?(:ip_list)

    report_file.puts('### IP Infomation')
    report_file.puts("\n")

    status_vulenv[:ip_list].each do |ip|
      case status_vulenv[:os][:name]
      when 'windows' then report_file.puts("#### Network Adapter: #{ip[:adapter]}")
      else report_file.puts("#### Interface: #{ip[:interface]}")
      end
      report_file.puts("- IPv4: #{ip[:inet]}")
      report_file.puts("- IPv6: #{ip[:inet6]}")
      report_file.puts("\n")
    end

    report_file.puts("\n")
  end

  def write_port_list(report_file, status_vulenv)
    return unless status_vulenv.key?(:port_list)

    report_file.puts('### Port')
    status_vulenv[:port_list].each do |socket|
      output = socket[:port] == socket[:service] ? "- #{socket[:port]}/#{socket[:protocol]}" : "- #{socket[:port]}/#{socket[:protocol]}(#{socket[:service]})"
      report_file.puts(output)
    end
    report_file.puts("\n")
  end

  def write_service_list(report_file, status_vulenv)
    return unless status_vulenv.key?(:service_list)

    report_file.puts('### Services')
    status_vulenv[:service_list].each { |service| report_file.puts("- #{service}") }
    report_file.puts("\n")
  end

  def write_error_of_vulenv(report_file)
    report_file.puts("## Root Cause\n\n")
    msg_of_cause = control_vulenv.error[:cause].split("\n")
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
