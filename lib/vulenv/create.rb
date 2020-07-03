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
require 'lib/ansible/core'
require 'lib/vagrant/core'

module Vulenv
  class Create
    attr_reader :vagrant, :ansible

    def initialize(args)
      @env_dir = args[:env_dir]
      @env_config = args[:env_config]

      @os = {
        name: @env_config['construction']['os']['name'],
        version: @env_config['construction']['os']['version'],
        install_method: @env_config['construction']['os']['default_method']
      }
      @users_param = @env_config['construction'].fetch('user', [])
      @msf_param = @env_config['attack_vector'] == 'local'
      @services_param = @env_config['construction'].fetch('services', [])
      @content_param = @env_config['construction'].fetch('content', nil)
      @related_softwares = @env_config['construction'].fetch('related_software', [])
      @vul_software = @env_config['construction'].fetch('vul_software', [])

      @vagrant = nil
      @ansible = nil
    end

    def exec
      @vagrant = prepare_vagrant
      vagrant.create

      @ansible = prepare_ansible
      ansible.create
    end

    private

    def prepare_vagrant
      @vagrant = Vagrant::Core.new(
        os_name: @os[:name],
        os_version: @os[:version],
        host: '192.168.177.177',
        env_dir: @env_dir
      )
    end

    def prepare_ansible
      softwares = @related_softwares.map { |software| software }
      softwares.push(@vul_software) unless @vul_software.empty?

      Ansible::Core.new(
        hosts: '192.168.177.177',
        os_name: @os[:name],
        os_version: @os[:version],
        install_method: @os[:install_method],
        host: '192.168.177.177',
        env_dir: @env_dir,
        users: @users_param,
        msf: @msf_param,
        services: @services_param,
        content: @content_param,
        softwares: softwares
      )
    end
  end
end
