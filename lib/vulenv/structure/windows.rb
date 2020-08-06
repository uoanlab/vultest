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
require 'winrm'

module Vulenv
  module Structure
    class Windows
      def initialize(args)
        @host = args[:host]
        @user = args[:user]
        @password = args[:password]
        @env_config = args[:env_config]
      end

      def retrieve_os
        conn = prepare_winrm

        base = nil
        conn.shell(:powershell) do |shell|
          shell.run('$PSVersionTable') do |stdout, _stderr|
            base = stdout.split(' ')[1] if stdout.include?('BuildVersion')
          end
        end

        {
          name: @env_config['construction']['os']['name'],
          version: @env_config['construction']['os']['version'],
          base_version: base,
          vulnerability: @env_config['construction']['os']['vulnerability']
        }
      end

      def retrieve_vul_software
        return { name: nil, version: nil } unless @env_config['construction'].key?('vul_software')

        {
          name: @env_config['construction']['vul_software']['name'],
          version: @env_config['construction']['vul_software']['version']
        }
      end

      def retrieve_related_softwares
        return [] unless @env_config['construction'].key?('related_software')

        @env_config['construction']['related_software'].map do |s|
          {
            name: s['name'],
            version: s.fetch('version', 'The latest version of the repository')
          }
        end
      end

      def retrieve_ipaddrs
        conn = prepare_winrm

        ipaddrs = []
        conn.shell(:powershell) do |shell|
          ip = {}
          shell.run('ipconfig') do |stdout, _stderr|
            ip[:adapter] = stdout.split(':')[0] if stdout != "\r\n" && stdout[0] != ' '
            ip[:inet] = stdout.split(':')[1].gsub(' ', '') if stdout.include?('IPv4')
            ip[:inet6] = stdout.split(':', 2)[1].gsub(' ', '') if stdout.include?('IPv6')

            if ip.key?(:adapter) && ip.key?(:inet) && ip.key?(:inet6)
              ipaddrs.push(ip)
              ip = {}
            end
          end
        end
        ipaddrs
      end

      def retrieve_services
        conn = prepare_winrm

        services = []
        conn.shell(:powershell) do |shell|
          shell.run('get-service') do |stdout, _stderr|
            service = stdout.split(' ')
            services.push(service[1]) if service[0] == 'Running'
          end
        end

        services
      end

      def retrieve_port_list
        conn = prepare_winrm

        ip_list = []
        socket_service_stdout = []
        socket_port_stdout = []

        conn.shell(:powershell) do |shell|
          shell.run('netstat -a') { |stdout, _stderr| socket_service_stdout.push(stdout) }
          shell.run('netstat -an') { |stdout, _stderr| socket_port_stdout.push(stdout) }
        end

        socket_port_stdout.each_with_index do |stdout, index|
          next if (index >= 0 && index <= 3) || socket_service_stdout[index].nil?

          service = socket_service_stdout[index].split(' ')[1].split(':')[-1]

          stdout_array = stdout.split(' ')
          protocol = stdout_array[0]
          port = stdout_array[1].split(':')[-1]

          next unless ip_list.find { |s| s[:port] == port }.nil?

          ip_list.push({ protocol: protocol, port: port, service: service })
        end

        ip_list
      end

      private

      def prepare_winrm
        opts = { endpoint: "http://#{@host}:5985/wsman", user: @user, password: @password }
        WinRM::Connection.new(opts)
      end
    end
  end
end
