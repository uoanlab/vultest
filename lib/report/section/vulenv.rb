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
    class Vulenv < Base
      attr_reader :status_vulenv

      def initialize(args)
        vulenv = args[:vulenv]
        @status_vulenv = vulenv.operating_environment.structure(vulenv.error[:flag])
      end

      def create
        section = "## Target Host\n\n"
        section << vulenv_construction_section
        section << ip_section
        section << port_section
        section << service_section
      end

      private

      def vulenv_construction_section
        section = vul_software_section
        section << related_software_section
      end

      def vul_software_section
        section = "### Vulnerable Software\n"

        unless status_vulenv[:os][:vulnerability]
          section << "- #{status_vulenv[:vul_software][:name]} : #{status_vulenv[:vul_software][:version]}\n\n"
          section << "### Operating System\n"
        end

        section << os_section
      end

      def os_section
        section = "- Name: #{status_vulenv[:os][:name]}\n"
        section << "- Version: #{status_vulenv[:os][:version]}\n"

        unless status_vulenv[:base_version_of_os].nil?
          section << case status_vulenv[:os][:name]
                     when 'windows' then '- Build Version: '
                     else '- Kernel Version: '
                     end
          section << "#{status_vulenv[:base_version_of_os]}\n"
        end
        section << "\n"
      end

      def related_software_section
        return '' if status_vulenv[:related_software].nil?

        section = "### Related Software\n"
        status_vulenv[:related_software].each { |software| section << "- #{software[:name]} : #{software[:version]}\n" }
        section << "\n"
      end

      def ip_section
        return '' unless status_vulenv.key?(:ip_list)

        section = "### IP Infomation\n\n"

        status_vulenv[:ip_list].each do |ip|
          section << case status_vulenv[:os][:name]
                     when 'windows' then "#### Network Adapter: #{ip[:adapter]}\n"
                     else "#### Interface: #{ip[:interface]}\n"
                     end
          section << "- IPv4: #{ip[:inet]}\n"
          section << "- IPv6: #{ip[:inet6]}\n\n"
        end

        section << "\n"
      end

      def port_section
        return '' unless status_vulenv.key?(:port_list)

        section = "### Port\n"
        status_vulenv[:port_list].each do |socket|
          section << if socket[:port] == socket[:service] then "- #{socket[:port]}/#{socket[:protocol]}\n"
                     else "- #{socket[:port]}/#{socket[:protocol]}(#{socket[:service]})\n"
                     end
        end
        section << "\n"
      end

      def service_section
        return '' unless status_vulenv.key?(:service_list)

        section = "### Services\n"
        status_vulenv[:service_list].each { |service| section << "- #{service}\n" }
        section << "\n"
      end
    end
  end
end
