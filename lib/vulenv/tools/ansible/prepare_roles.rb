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

require './lib/vulenv/tools/ansible/role/metasploit'
require './lib/vulenv/tools/ansible/role/user'
require './lib/vulenv/tools/ansible/role/software/apt'
require './lib/vulenv/tools/ansible/role/software/yum'
require './lib/vulenv/tools/ansible/role/software/gem'
require './lib/vulenv/tools/ansible/role/software/source'
require './lib/vulenv/tools/ansible/role/content'
require './lib/vulenv/tools/ansible/role/service'

class PrepareRoles
  attr_reader :role_dir, :db_path, :env_config, :cve, :attack_vector

  def initialize(args)
    @role_dir = args[:role_dir]
    @db_path = args[:db_path]
    @env_config = args[:env_config]
    @cve = args[:cve]
    @attack_vector = args[:attack_vector]
  end

  def create
    if attack_vector == 'local'
      role = Ansible::Role::Metasploit.new(role_dir: role_dir)
      role.create
    end

    user_parameter

    default_method = env_config['os'].fetch('default_method', nil)
    related_software_parameter(default_method)
    vul_software_parameter(default_method)

    content_parameter
    services_parameter
  end

  private

  def user_parameter
    return unless env_config.key?('user')

    role = Ansible::Role::User.new(role_dir: role_dir, users: env_config['user'])
    role.create
  end

  def related_software_parameter(default_method)
    return unless env_config.key?('related_software')

    env_config['related_software'].each do |software|
      method = software.fetch('method', default_method)
      role =
        case method
        when 'apt' then Ansible::Role::Software::Apt.new(role_dir: role_dir, software: software)
        when 'yum' then Ansible::Role::Software::Yum.new(role_dir: role_dir, software: software)
        when 'gem' then Ansible::Role::Software::Gem.new(role_dir: role_dir, software: software)
        when 'source' then Ansible::Role::Software::Source.new(role_dir: role_dir, software: software)
        end
      role.create
    end
  end

  def vul_software_parameter(default_method)
    return unless env_config.key?('vul_software')

    method = env_config['vul_software'].fetch('method', default_method)
    role =
      case method
      when 'apt' then Ansible::Role::Software::Apt.new(role_dir: role_dir, software: env_config['vul_software'])
      when 'yum' then Ansible::Role::Software::Yum.new(role_dir: role_dir, software: env_config['vul_software'])
      when 'gem' then Ansible::Role::Software::Gem.new(role_dir: role_dir, software: env_config['vul_software'])
      when 'source' then Ansible::Role::Software::Source.new(role_dir: role_dir, software: env_config['vul_software'])
      end
    role.create
  end

  def content_parameter
    return unless env_config.key?('content')

    role = Ansible::Role::Content.new(role_dir: role_dir, db_path: db_path, cve: cve, content: env_config['content'])
    role.create
  end

  def services_parameter
    return unless env_config.key?('services')

    env_config['services'].each do |service|
      role = Ansible::Role::Service.new(role_dir: role_dir, service: service)
      role.create
    end
  end
end
