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
require 'net/ssh'
require 'winrm'

module VulenvSpec
  def ip_list_in_linux
    ip_list = []
    Net::SSH.start('192.168.177.177', 'vagrant', password: 'vagrant', verify_host_key: :never) do |ssh|
      cmd = ssh.exec!('sudo find / -name ip').split("\n")[0]
      cmd += ' addr | grep inet'

      ssh.exec!(cmd).split("\n").each_slice(2) { |ip| ip_list.push({ interface: ip[0].split(' ')[-1], inet: ip[0].split(' ')[1], inet6: ip[1].split(' ')[1] }) }
    end
    ip_list
  end

  def ip_list_in_windows
    opts = { endpoint: 'http://192.168.177.177:5985/wsman', user: 'vagrant', password: 'vagrant' }

    conn = WinRM::Connection.new(opts)

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

  def port_list_in_linux
    socket = []
    Net::SSH.start('192.168.177.177', 'vagrant', password: 'vagrant', verify_host_key: :never) do |ssh|
      cmd = ssh.exec!('sudo find / -name ss').split("\n")[0]

      socket_service_stdout = ssh.exec!("#{cmd} -atu").split("\n")
      ssh.exec!("#{cmd} -antu").split("\n").each_with_index do |stdout, index|
        next if index.zero?

        service = socket_service_stdout[index].split(' ')[4].split(':')[-1]

        stdout_array = stdout.split(' ')
        protocol = stdout_array[0]
        port = stdout_array[4].split(':')[-1]

        next unless socket.find { |s| s[:port] == port }.nil?

        socket.push({ protocol: protocol, port: port, service: service })
      end
    end

    socket
  end

  def port_list_in_windows
    opts = { endpoint: 'http://192.168.177.177:5985/wsman', user: 'vagrant', password: 'vagrant' }

    conn = WinRM::Connection.new(opts)
    socket = []
    socket_service_stdout = []
    socket_port_stdout = []

    conn.shell(:powershell) do |shell|
      shell.run('netstat -a') { |stdout, _stderr| socket_service_stdout.push(stdout) }
      shell.run('netstat -an') { |stdout, _stderr| socket_port_stdout.push(stdout) }
    end

    socket_port_stdout.each_with_index do |stdout, index|
      next if index >= 0 && index <= 3

      service = socket_service_stdout[index].split(' ')[1].split(':')[-1]

      stdout_array = stdout.split(' ')
      protocol = stdout_array[0]
      port = stdout_array[1].split(':')[-1]

      next unless socket.find { |s| s[:port] == port }.nil?

      socket.push({ protocol: protocol, port: port, service: service })
    end

    socket
  end

  def service_list_in_ubuntu
    running_service = []
    Net::SSH.start('192.168.177.177', 'vagrant', password: 'vagrant', verify_host_key: :never) do |ssh|
      cmd = ssh.exec!('sudo find / -name service | grep bin/').split("\n")[0]
      cmd = "sudo #{cmd} --status-all | grep +"
      ssh.exec!(cmd).gsub('[', '').gsub(']', '').split("\n").each { |stdout| running_service.push(stdout.split(' ')[1]) if stdout.split(' ')[0] == '+' }
    end

    running_service
  end

  def service_list_in_centos
    running_service = []
    Net::SSH.start('192.168.177.177', 'vagrant', password: 'vagrant', verify_host_key: :never) do |ssh|
      cmd = ssh.exec!('sudo find / -name service | grep bin/').split("\n")[0]
      cmd = "sudo #{cmd} --status-all | grep running..."
      ssh.exec!(cmd).split("\n").each { |stdout| running_service.push(stdout.split(' ')[0]) }
    end

    running_service
  end

  def service_list_in_windows
    opts = { endpoint: 'http://192.168.177.177:5985/wsman', user: 'vagrant', password: 'vagrant' }
    conn = WinRM::Connection.new(opts)

    running_service = []
    conn.shell(:powershell) do |shell|
      shell.run('get-service') do |stdout, _stderr|
        service = stdout.split(' ')
        running_service.push(service[1]) if service[0] == 'Running'
      end
    end

    return running_service
  end
end
