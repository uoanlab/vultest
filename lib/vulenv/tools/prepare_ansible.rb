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

require 'fileutils'

require './lib/vulenv/config/local'
require './lib/vulenv/config/user'
require './lib/vulenv/config/software'
require './lib/vulenv/config/content'
require './lib/vulenv/config/prepare'
require './lib/vulenv/config/services'

class PrepareAnsible
  include Local
  include User
  include Software
  include Content
  include Prepare
  include Services

  def initialize(args)
    @cve = args[:cve]
    @target_os = args[:os_name]
    @db_path = args[:db_path]
    @env_config = args[:env_config]

    @attack_vector = args[:attack_vector]

    @ansible_dir = {}
    @ansible_dir[:base] = "#{args[:env_dir]}/ansible"
    @ansible_dir[:hosts] = "#{@ansible_dir[:base]}/hosts"
    @ansible_dir[:playbook] = "#{@ansible_dir[:base]}/playbook"
    @ansible_dir[:roles] =  "#{@ansible_dir[:base]}/roles"

    FileUtils.mkdir_p(@ansible_dir[:base].to_s)
    FileUtils.mkdir_p(@ansible_dir[:hosts].to_s)
    FileUtils.mkdir_p(@ansible_dir[:playbook].to_s)
    FileUtils.mkdir_p(@ansible_dir[:roles].to_s)

    if @target_os == 'windows'
      FileUtils.cp_r('./lib/vulenv/tools/data/ansible/hosts/windows/hosts.yml', "#{@ansible_dir[:hosts]}/hosts.yml")
    else
      FileUtils.cp_r('./lib/vulenv/tools/data/ansible/ansible.cfg', "#{@ansible_dir[:base]}/ansible.cfg")
      FileUtils.cp_r('./lib/vulenv/tools/data/ansible/hosts/linux/hosts.yml', "#{@ansible_dir[:hosts]}/hosts.yml")
    end
  end

  def create
    local(@ansible_dir[:roles]) if @attack_vector == 'local'

    user(users: @env_config['user'], role_dir: @ansible_dir[:roles]) if @env_config.key?('user')

    default_method = @env_config['os'].key?('default_method') ? @env_config['os']['default_method'] : nil
    if @env_config.key?('related_software')
      related_software(default_method: default_method, softwares: @env_config['related_software'], role_dir: @ansible_dir[:roles])
    end
    vul_software(default_method: default_method, vul_software: @env_config['vul_software'], role_dir: @ansible_dir[:roles]) if @env_config.key?('vul_software')

    content(db: @db_path, cve: @cve, content_info: @env_config['content'], role_dir: @ansible_dir[:roles]) if @env_config.key?('content')

    services(role_dir: @ansible_dir[:roles], services: @env_config['services']) if @env_config.key?('services')

    create_playbook
  end

  private

  def create_playbook
    File.open("#{@ansible_dir[:playbook]}/main.yml", 'w') do |playbook_file|
      playbook_file.puts("---\n- hosts: vagrant\n  ")
      playbook_file.puts("  connection: local \n  become: yes \n  roles: ") unless @target_os == 'windows'
      playbook_file.puts('    - ../roles/user') if @env_config.key?('user')

      if @env_config.key?('related_software')
        @env_config['related_software'].each do |software|
          playbook_file.puts("    - ../roles/#{software['name']} ")
        end
      end

      playbook_file.puts("    - ../roles/#{@env_config['vul_software']['name']} ") if @env_config.key?('vul_software')
      playbook_file.puts("    - ../roles/#{@cve} ") if @env_config.key?('content')
      playbook_file.puts('    - ../roles/metasploit') if @attack_vector == 'local'

      @env_config['services'].each { |service_name| playbook_file.puts("    - ../roles/service-#{service_name} ") } if @env_config.key?('services')
    end
  end
end
