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

require 'lib/vagrant/vagrantfile/base'

module Vagrant
  module Vagrantfile
    class AttackEnv < Base
      attr_reader :host

      def initialize(args)
        super(env_dir: args[:env_dir])
        @host = args[:host]
      end

      def create
        create_vagrantfile
      end

      private

      def create_vagrantfile
        content = "# -*- mode: ruby -*-\n"
        content << "# vi: set ft=ruby :\n\n"

        content << "Vagrant.configure(2) do |config|\n\n"
        content << "  config.vm.box = 'redsloop/ubuntu-18.04.1'\n"
        content << "  config.vm.box_version = '2.0'\n\n"

        content << "  config.ssh.username = 'vagrant'\n"
        content << "  config.ssh.password = 'vagrant'\n\n"

        content << "  config.vm.network 'private_network', ip: '#{host}'\n\n"

        content << "  config.vm.provision 'ansible_local', run: 'always' do |ansible|\n"
        content << "    ansible.playbook = './ansible/playbook/main.yml'\n"
        content << "    ansible.inventory_path = './ansible/hosts/hosts.yml'\n"
        content << "    ansible.config_file = './ansible/ansible.cfg'\n"
        content << "    ansible.limit = 'all'\n"
        content << "  end\n\n"
        content << 'end'

        File.open("#{env_dir}/Vagrantfile", 'w') { |file| file.puts(content) }
      end
    end
  end
end
