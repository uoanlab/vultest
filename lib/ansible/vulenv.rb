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

require './lib/ansible/base'
require './lib/ansible/playbook/vulenv'
require './lib/ansible/role/vulenv'

module Ansible
  class Vulenv < Base
    attr_reader :db_path, :cve, :os, :env_config, :attack_vector

    def initialize(args)
      super(env_dir: args[:env_dir])

      @db_path = args[:db_path]

      @os = args[:os_name]
      @env_config = args[:env_config]

      @cve = args[:cve]
      @attack_vector = args[:attack_vector]
    end

    private

    def create_hosts
      if os == 'windows'
        FileUtils.cp_r('./data/ansible/hosts/windows/hosts.yml', "#{ansible_dir[:hosts]}/hosts.yml")
      else
        FileUtils.cp_r('./data/ansible/ansible.cfg', "#{ansible_dir[:base]}/ansible.cfg")
        FileUtils.cp_r('.//data/ansible/hosts/linux/hosts.yml', "#{ansible_dir[:hosts]}/hosts.yml")
      end
    end

    def create_roles
      prepare_roles = Role::Vulenv.new(
        role_dir: ansible_dir[:roles],
        db_path: db_path,
        env_config: env_config,
        cve: cve,
        attack_vector: attack_vector
      )
      prepare_roles.create
    end

    def create_playbook
      prepare_playbook = Playbook::Vulenv.new(
        os: os,
        env_config: env_config,
        playbook_dir: ansible_dir[:playbook],
        cve: cve,
        attack_vector: attack_vector
      )
      prepare_playbook.create
    end
  end
end
