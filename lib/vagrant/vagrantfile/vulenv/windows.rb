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

require 'bundler/setup'
require 'fileutils'
require 'open3'

require './lib/vagrant/vagrantfile/vulenv/base'

module Vagrant
  module Vagrantfile
    module Vulenv
      class Windows < Base
        def create
          puts("Please, you select a vagrant image below:\n  OS name: #{os_name}\n  OS version: #{os_version}")
          box = select_vagrant_image_in_local

          create_vagrantfile(box)
          return unless os_name == 'windows'

          Dir.chdir(env_dir) do
            Open3.capture3('wget https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1')
          end
        end

        private

        def create_vagrantfile(args)
          content = "# -*- mode: ruby -*-\n"
          content << "# vi: set ft=ruby :\n\n"

          content << "Vagrant.configure(2) do |config|\n\n"
          content << "  config.vm.box = '#{args[:box_name]}'\n"
          content << "  config.vm.box_version = '#{args[:box_version]}'\n\n" if args.key?(:box_version) && !args[:box_version].empty?

          content << "  config.vm.guest = :windows\n"
          content << "  config.vm.communicator = 'winrm'\n"
          content << "  config.winrm.username = 'vagrant'\n"
          content << "  config.winrm.password = 'vagrant'\n"
          content << "  config.winrm.retry_limit = 30\n\n"

          content << "  config.vm.network 'private_network', ip: '192.168.177.177'\n"
          content << "  config.vm.network :forwarded_port, guest: 3389, host: 13_389\n"
          content << "  config.vm.network :forwarded_port, guest: 5985, host: 15_985, id: 'winrm', auto_correct: true\n\n"

          content << "  config.vm.provider 'virtualbox' do |vb|\n"
          content << "    vb.gui = true\n"
          content << "  end\n\n"

          content << "  config.vm.provision 'shell' do |shell|\n"
          content << "    shell.path = 'ConfigureRemotingForAnsible.ps1'\n"
          content << "  end\n\n"

          content << "  config.vm.provision 'ansible', run: 'always' do |ansible|\n"
          content << "    ansible.playbook = './ansible/playbook/main.yml'\n"
          content << "    ansible.inventory_path = './ansible/hosts/hosts.yml'\n"
          content << "    ansible.limit = 'vagrant'\n"
          content << "  end\n\n"
          content << 'end'

          File.open("#{env_dir}/Vagrantfile", 'w') { |file| file.puts(content) }
        end
      end
    end
  end
end
