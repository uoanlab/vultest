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

require 'lib/ansible/roles/apt'
require 'lib/ansible/roles/content'
require 'lib/ansible/roles/gem'
require 'lib/ansible/roles/metasploit'
require 'lib/ansible/roles/service'
require 'lib/ansible/roles/source_install'
require 'lib/ansible/roles/user'
require 'lib/ansible/roles/yum'

module Ansible
  ANSIBLE_CONFIG_TEMPLATE_PATH = './resources/ansible/ansible.cfg.erb'.freeze
  ANSIBLE_HOSTS_TEMPLATE_PATH = './resources/ansible/hosts/hosts.yml.erb'.freeze
  ANSIBLE_PLAYBOOK_TEMPLATE_PATH = './resources/ansible/playbook/main.yml.erb'.freeze
  ANSIBLE_ROLES_TEMPLATE_PATH = './resources/ansible/roles'.freeze

  class Core
    def initialize(args)
      @ansible_dir = {
        base: "#{args[:env_dir]}/ansible",
        hosts: "#{args[:env_dir]}/ansible/hosts",
        playbook: "#{args[:env_dir]}/ansible/playbook",
        roles: "#{args[:env_dir]}/ansible/roles"
      }

      @host = args[:host]
      @os = {
        name: args[:os_name],
        version: args[:os_version],
        install_method: args[:install_method]
      }

      @env_config = {
        users: args.fetch(:users, []),
        msf: args.fetch(:msf, true),
        services: args.fetch(:services, []),
        content: args.fetch(:content, nil),
        softwares: args.fetch(:softwares, [])
      }
    end

    def create
      create_cfg
      create_hosts
      create_playbook
      create_roles
    end

    private

    def create_cfg
      FileUtils.mkdir_p(@ansible_dir[:base])

      erb = ERB.new(File.read(ANSIBLE_CONFIG_TEMPLATE_PATH), trim_mode: 2)
      File.open("#{@ansible_dir[:base]}/ansible.cfg", 'w') { |f| f.puts(erb.result(binding)) }
    end

    def create_hosts
      FileUtils.mkdir_p(@ansible_dir[:hosts])

      erb = ERB.new(File.read(ANSIBLE_HOSTS_TEMPLATE_PATH), trim_mode: 2)
      os_name = @os[:name]
      host = @host
      File.open("#{@ansible_dir[:hosts]}/hosts.yml", 'w') { |f| f.puts(erb.result(binding)) }
    end

    def create_playbook
      FileUtils.mkdir_p(@ansible_dir[:playbook])

      erb = ERB.new(File.read(ANSIBLE_PLAYBOOK_TEMPLATE_PATH), trim_mode: 2)
      os_name = @os[:name]
      users = @env_config[:users]
      msf = @env_config[:msf]
      softwares = @env_config[:softwares].map { |software| software['name'] }
      content = @env_config[:content]
      services = @env_config[:services]

      File.open("#{@ansible_dir[:playbook]}/main.yml", 'w') do |f|
        f.puts(erb.result(binding))
      end
    end

    def create_roles
      Roles::Metasploit.create(role_dir: @ansible_dir[:roles], host: @host) if @env_config[:msf]

      @env_config[:users].each do |user|
        Roles::User.create(role_dir: @ansible_dir[:roles], user: user)
      end

      @env_config[:softwares].each do |software|
        install_method = software.fetch('method', @os[:install_method])
        case install_method
        when 'apt'
          Roles::Apt.create(role_dir: @ansible_dir[:roles], software: software)
        when 'yum'
          Roles::Yum.create(role_dir: @ansible_dir[:roles], software: software)
        when 'gem'
          Roles::Gem.create(role_dir: @ansible_dir[:roles], software: software)
        when 'source'
          Roles::SourceInstall.create(role_dir: @ansible_dir[:roles], software: software)
        end
      end

      unless @env_config[:content].nil?
        Roles::Content.create(role_dir: @ansible_dir[:roles], content: @env_config[:content])
      end

      @env_config[:services].each do |service|
        Roles::Service.create(role_dir: @ansible_dir[:roles], service: service)
      end
    end
  end
end
