# Copyright [2020] [University of Aizu]
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'bundler/setup'
require 'winrm'

require './lib/vulenv/vulenv'

class VulnevWindows < Vulenv
  private

  def base_version_of_os
    build_version
  end

  def ip_list
    conn = prepare_winrm

    ip_list = []
    conn.shell(:powershell) do |shell|
      ip = {}
      shell.run('ipconfig') do |stdout, _stderr|
        ip[:adapter] = stdout.split(':')[0] if stdout != "\r\n" && stdout[0] != ' '
        ip[:inet] = stdout.split(':')[1].gsub(' ', '') if stdout.include?('IPv4')
        ip[:inet6] = stdout.split(':', 2)[1].gsub(' ', '') if stdout.include?('IPv6')

        if ip.key?(:adapter) && ip.key?(:inet) && ip.key?(:inet6)
          ip_list.push(ip)
          ip = {}
        end
      end
    end
    ip_list
  end

  def port_list
    conn = prepare_winrm
    socket = []
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

      next unless socket.find { |s| s[:port] == port }.nil?

      socket.push({ protocol: protocol, port: port, service: service })
    end

    socket
  end

  def service_list
    conn = prepare_winrm

    running_service = []
    conn.shell(:powershell) do |shell|
      shell.run('get-service') do |stdout, _stderr|
        service = stdout.split(' ')
        running_service.push(service[1]) if service[0] == 'Running'
      end
    end

    return running_service
  end

  def prepare_winrm
    opts = { endpoint: 'http://192.168.177.177:5985/wsman', user: 'vagrant', password: 'vagrant' }
    WinRM::Connection.new(opts)
  end

  def build_version
    conn = prepare_winrm

    build_version = nil
    conn.shell(:powershell) do |shell|
      shell.run('$PSVersionTable') { |stdout, _stderr| build_version = stdout.split(' ')[1] if stdout.include?('BuildVersion') }
    end

    build_version
  end
end
