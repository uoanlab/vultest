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

require './lib/ansible/role/attack_env'
require './lib/ansible/playbook/attack_env'

module Ansible
  class AttackEnv < Base
    attr_reader :host

    def initialize(args)
      super(env_dir: args[:env_dir])
      @host = args[:host]
    end

    private

    def create_hosts
      FileUtils.cp_r('./data/ansible/ansible.cfg', "#{ansible_dir[:base]}/ansible.cfg")

      File.open("#{ansible_dir[:hosts]}/hosts.yml", 'w') do |vars_file|
        vars_file.puts('---')
        vars_file.puts('vagrant:')
        vars_file.puts("  hosts: #{host}")
      end
    end

    def create_roles
      prepare_roles = Role::AttackEnv.new(role_dir: ansible_dir[:roles], host: host)
      prepare_roles.create
    end

    def create_playbook
      prepare_playbook = Playbook::AttackEnv.new(playbook_dir: ansible_dir[:playbook])
      prepare_playbook.create
    end
  end
end
