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
require 'tty-prompt'

require 'lib/vagrant/vagrantfile/vulenv/base'

module Vagrant
  module Vagrantfile
    module Vulenv
      class Linux < Base
        def create
          if TTY::Prompt.new.yes?('Do you select a vagrant image in local?')
            puts("Please, you select a vagrant image below:\n  OS name: #{os_name}\n  OS version: #{os_version}")
            box = select_vagrant_image_in_local

            create_vagrantfile(box)
          elsif TTY::Prompt.new.yes?('Do you select a vagrant image in Vagrant Cloud?')
            box = {}
            puts("Please, you input a vagrant image below:\n  OS name: #{os_name}\n  OS version: #{os_version}")

            print('Name of Vagrant image: ')
            box[:box_name] = gets.chomp!

            print('Version of Vagrant image: ')
            box[:box_version] = gets.chomp!

            create_vagrantfile(box)

          elsif File.exist?("./data/vagrant/#{os_name}/#{os_version}/Vagrantfile")
            FileUtils.cp_r("./data/vagrant/#{os_name}/#{os_version}/Vagrantfile", "#{env_dir}/Vagrantfile")
          end
        end

        private

        def create_vagrantfile(args)
          content = "# -*- mode: ruby -*-\n"
          content << "# vi: set ft=ruby :\n\n"

          content << "Vagrant.configure(2) do |config|\n\n"
          content << "  config.vm.box = '#{args[:box_name]}'\n"
          content << "  config.vm.box_version = '#{args[:box_version]}'\n\n" if args.key?(:box_version) && !args[:box_version].empty?

          content << "  config.vm.network 'private_network', ip: '192.168.177.177'\n"
          content << "  config.vm.network 'forwarded_port', guest: 80, host: 65_434\n\n"

          unless os_name.scan(/CentOS/i).empty?
            content << "  config.vm.provision 'shell', inline: <<-SHELL\n"
            content << "    yum update nss -y\n"
            content << "  SHELL\n\n"
          end

          content << "  config.vm.provision 'ansible_local', run: 'always' do |ansible|\n"

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
