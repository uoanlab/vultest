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

require './lib/vulenv/tools/ansible/prepare_playbook'
require './lib/vulenv/tools/ansible/roles/metasploit_role'
require './lib/vulenv/tools/ansible/roles/user_role'
require './lib/vulenv/tools/ansible/roles/apt_role'
require './lib/vulenv/tools/ansible/roles/yum_role'
require './lib/vulenv/tools/ansible/roles/gem_role'
require './lib/vulenv/tools/ansible/roles/source_role'
require './lib/vulenv/tools/ansible/roles/content_role'
require './lib/vulenv/tools/ansible/roles/service_role'

class PrepareAnsible
  attr_reader :db_path, :cve, :os, :env_config, :attack_vector, :ansible_dir

  def initialize(args)
    @db_path = args[:db_path]

    @os = args[:os_name]
    @env_config = args[:env_config]

    @cve = args[:cve]
    @attack_vector = args[:attack_vector]

    @ansible_dir =
      {
        base: "#{args[:env_dir]}/ansible",
        hosts: "#{args[:env_dir]}/ansible/hosts",
        playbook: "#{args[:env_dir]}/ansible/playbook",
        roles: "#{args[:env_dir]}/ansible/roles"
      }
  end

  def create
    ansible_dir.each { |_key, value| FileUtils.mkdir_p(value.to_s) }
    create_hosts
    create_roles
    create_playbook
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
    if attack_vector == 'local'
      role = MetasploitRole.new(role_dir: ansible_dir[:roles])
      role.create
    end

    if env_config.key?('user')
      role = UserRole.new(role_dir: ansible_dir[:roles], users: env_config['user'])
      role.create
    end

    default_method = env_config['os'].fetch('default_method', nil)
    if env_config.key?('related_software')
      env_config['related_software'].each do |software|
        method = software.fetch('method', default_method)
        role =
          case method
          when 'apt' then AptRole.new(role_dir: ansible_dir[:roles], software: software)
          when 'yum' then YumRole.new(role_dir: ansible_dir[:roles], software: software)
          when 'gem' then GemRole.new(role_dir: ansible_dir[:roles], software: software)
          when 'source' then SourceRole.new(role_dir: ansible_dir[:roles], software: software)
          end
        role.create
      end
    end

    if env_config.key?('vul_software')
      method = env_config['vul_software'].fetch('method', default_method)
      role =
        case method
        when 'apt' then AptRole.new(role_dir: ansible_dir[:roles], software: env_config['vul_software'])
        when 'yum' then YumRole.new(role_dir: ansible_dir[:roles], software: env_config['vul_software'])
        when 'gem' then GemRole.new(role_dir: ansible_dir[:roles], software: env_config['vul_software'])
        when 'source' then SourceRole.new(role_dir: ansible_dir[:roles], software: env_config['vul_software'])
        end
      role.create
    end

    if env_config.key?('content')
      role = ContentRole.new(role_dir: ansible_dir[:roles], db_path: db_path, cve: cve, content: env_config['content'])
      role.create
    end

    if env_config.key?('services')
      env_config['services'].each do |service|
        role = ServiceRole.new(role_dir: ansible_dir[:roles], service: service)
        role.create
      end
    end
  end

  def create_playbook
    prepare_playbook = PreparePlaybook.new(
      os: os,
      env_config: env_config,
      playbook_dir: ansible_dir[:playbook],
      cve: cve,
      attack_vector: attack_vector
    )
    prepare_playbook.create
  end
end
