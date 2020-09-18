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
require 'erb'
require 'fileutils'
require 'yaml'

require 'lib/ansible/config'
require 'lib/ansible/hosts'
require 'lib/ansible/playbook'
require 'lib/ansible/role'

module Ansible
  ANSIBLE_CONFIG_TEMPLATE_PATH = './resources/ansible/ansible.cfg'.freeze
  ANSIBLE_HOSTS_TEMPLATE_PATH = './resources/ansible/inventory/hosts.yml.erb'.freeze
  ANSIBLE_PLAYBOOK_TEMPLATE_PATH = './resources/ansible/playbook.yml.erb'.freeze
  ANSIBLE_ROLES_TEMPLATE_PATH = './resources/ansible/roles'.freeze

  class Core
    def initialize(args)
      @ansible_dir = {
        base: "#{args[:env_dir]}/ansible",
        hosts: "#{args[:env_dir]}/ansible/inventory",
        role: "#{args[:env_dir]}/ansible/roles"
      }

      @host = args[:host]
      @os = {
        name: args[:os_name],
        version: args[:os_version]
      }

      @env_config = {
        users: args.fetch(:users, []),
        software: args.fetch(:software, []),
        attack_method: args.fetch(:attack_method, nil)
      }

      @playbook = nil
    end

    def create
      create_cfg
      create_hosts
      create_playbook
      create_roles
    end

    private

    def create_cfg
      Config.new(@ansible_dir[:base]).create
    end

    def create_hosts
      Hosts.new(@ansible_dir[:hosts]).create(@host, @os[:name])
    end

    def create_playbook
      @playbook = Playbook.new(@ansible_dir[:base])
      @playbook.create(@os[:name])
    end

    def create_roles
      Role.new(@playbook, @ansible_dir[:role]).create(@host, @env_config)
    end
  end
end
