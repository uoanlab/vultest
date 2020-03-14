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

require './lib/vulenv/vulenv'

class VulnevLinux < Vulenv
  def base_version_of_os
    kernel_version
  end

  def ip_list
    ip_list = []
    Net::SSH.start('192.168.177.177', 'vagrant', password: 'vagrant', verify_host_key: :never) do |ssh|
      cmd = ssh.exec!('sudo find / -name ip | grep bin/').split("\n")[0]
      cmd += ' addr | grep inet'

      ssh.exec!(cmd).split("\n").each_slice(2) { |ip| ip_list.push({ interface: ip[0].split(' ')[-1], inet: ip[0].split(' ')[1], inet6: ip[1].split(' ')[1] }) }
    end
    ip_list
  end

  def port_list
    socket = []
    Net::SSH.start('192.168.177.177', 'vagrant', password: 'vagrant', verify_host_key: :never) do |ssh|
      cmd = ssh.exec!('sudo find / -name ss | grep bin/').split("\n")[0]

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

  def service_list
    raise NotImplementedError
  end

  private

  def kernel_version
    Net::SSH.start('192.168.177.177', 'vagrant', password: 'vagrant', verify_host_key: :never) { |ssh| ssh.exec!('uname -r') }
  end
end
