# Copyright [2019] [University of Aizu]
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

require 'fileutils'
require_relative '../../build/params'

class Ansible
  include ConstructionParams

  def initialize(config, env_config, env_dir)
    @config = config
    @env_config = env_config
    @env_dir = env_dir

    @ansible_dir = {}
    @ansible_dir[:base] = "#{@env_dir}/ansible"
    @ansible_dir[:hosts] = "#{@ansible_dir[:base]}/hosts"
    @ansible_dir[:playbook] = "#{@ansible_dir[:base]}/playbook"
    @ansible_dir[:roles] =  "#{@ansible_dir[:base]}/roles"

    FileUtils.mkdir_p(@ansible_dir[:base].to_s)
    FileUtils.mkdir_p(@ansible_dir[:hosts].to_s)
    FileUtils.mkdir_p(@ansible_dir[:playbook].to_s)
    FileUtils.mkdir_p(@ansible_dir[:roles].to_s)

    FileUtils.cp_r('./build/ansible/ansible.cfg', "#{@ansible_dir[:base]}/ansible.cfg")
    FileUtils.cp_r('./build/ansible/hosts/hosts.yml', "#{@ansible_dir[:hosts]}/hosts.yml")
  end

  def create
    local(@ansible_dir) if @env_config['attack_vector'] == 'local'
    user(@env_config, @ansible_dir) if @env_config['construction'].key?('user')
    related_software(@env_config, @ansible_dir) if @env_config['construction'].key?('related_software')
    vul_software(@env_config, @ansible_dir) if @env_config['construction'].key?('vul_software')
    content(@config, @env_config, @ansible_dir) if @env_config['construction'].key?('content')
    create_playbook
  end

  private

  def create_playbook
    File.open("#{@ansible_dir[:playbook]}/main.yml", 'w') do |playbook_file|
      playbook_file.puts("---\n- hosts: vagrant\n  connection: local \n  become: yes \n  roles: ")
      playbook_file.puts('    - ../roles/user') if @env_config['construction'].key?('user')

      if @env_config['construction'].key?('related_software')
        @env_config['construction']['related_software'].each do |software|
          playbook_file.puts("    - ../roles/#{software['name']} ")
        end
      end

      playbook_file.puts("    - ../roles/#{@env_config['construction']['vul_software']['name']} ") if @env_config['construction'].key?('vul_software')
      playbook_file.puts("    - ../roles/#{@env_config['cve']} ") if @env_config['construction'].key?('content')
      playbook_file.puts('    - ../roles/metasploit') if @env_config['attack_vector'] == 'local'
    end
  end
end
