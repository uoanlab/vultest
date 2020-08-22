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

require 'lib/ansible/roles/add_to_file'
require 'lib/ansible/roles/attack_tool_msf'
require 'lib/ansible/roles/create_file'
require 'lib/ansible/roles/patch_download'
require 'lib/ansible/roles/patch_install'
require 'lib/ansible/roles/replace_in_file'

require 'lib/ansible/roles/software/build'
require 'lib/ansible/roles/software/configure'
require 'lib/ansible/roles/software/download'
require 'lib/ansible/roles/software/package'
require 'lib/ansible/roles/software/service'

require 'lib/ansible/roles/user'

module Ansible
  ANSIBLE_CONFIG_TEMPLATE_PATH = './resources/ansible/ansible.cfg'.freeze
  ANSIBLE_HOSTS_TEMPLATE_PATH = './resources/ansible/hosts/hosts.yml.erb'.freeze
  ANSIBLE_PLAYBOOK_TEMPLATE_PATH = './resources/ansible/playbook.yml.erb'.freeze
  ANSIBLE_ROLES_TEMPLATE_PATH = './resources/ansible/roles'.freeze

  class Core
    def initialize(args)
      @ansible_dir = {
        base: "#{args[:env_dir]}/ansible",
        hosts: "#{args[:env_dir]}/ansible/hosts",
        role: "#{args[:env_dir]}/ansible/roles"
      }

      @host = args[:host]
      @os = {
        name: args[:os_name],
        version: args[:os_version]
      }

      @env_config = {
        users: args.fetch(:users, []),
        softwares: args.fetch(:softwares, []),
        attack_tool: args.fetch(:attack_tool, nil)
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
      FileUtils.mkdir_p((@ansible_dir[:role]).to_s)

      if @env_config[:attack_tool] == 'msf'
        Roles::AttackToolMSF.new(
          role_dir: @ansible_dir[:role],
          host: @host
        ).create
        @playbook.add('    - attack.tool.msf')
      end

      @env_config[:users].each do |user|
        Roles::User.new(
          role_dir: @ansible_dir[:role],
          user_name: user['name'],
          user_shell: user['shell']
        ).create
        @playbook.add("    - #{user['name']}.user")
      end

      create_software(@env_config[:softwares])
    end

    def create_software(softwares)
      softwares.each do |software|
        create_software(software['softwares']) if software.key?('softwares')

        method = software.fetch('method', '')
        software_version = software.fetch('version', nil)
        patch_version = nil
        if software.key?('patch')
          software_version = "#{software['version'].split('.')[0]}.#{software['version'].split('.')[1]}"
          patch_version = software['version'].split('.')[2]
        end

        case method
        when 'source'
          Roles::Software::Download.new(
            role_dir: @ansible_dir[:role],
            software_name: software['name'],
            software_version: software_version,
            software_src_dir: software['src_dir']
          ).create
          @playbook.add("    - #{software['name']}.download")
        else
          Roles::Software::Package.new(
            role_dir: @ansible_dir[:role],
            software_name: software['name'],
            software_version: software_version
          ).create
          @playbook.add("    - #{software['name']}.package")
        end

        unless patch_version.nil?
          1.upto(patch_version.to_i) do |v|
            role = Roles::PatchDownload.new(
              role_dir: @ansible_dir[:role],
              software_name: software['name'],
              software_version: software_version,
              software_src_dir: software['src_dir'],
              patch_version: v
            )
            role.create
            @playbook.add("    - #{role.path}")

            role = Roles::PatchInstall.new(
              role_dir: @ansible_dir[:role],
              software_name: software['name'],
              software_version: software_version,
              software_src_dir: software['src_dir'],
              patch_version: v
            )
            role.create
            @playbook.add("    - #{role.path}")
          end
        end

        config = software.fetch('config', {})
        if config.key?('pre_config')
          create_pre_config(software['name'], software_version, software['src_dir'], config['pre_config'])
        end
        if config.key?('build')
          create_build(software['name'], software_version, software['src_dir'], config['build'])
        end
        create_post_config(config['post_config']) if config.key?('post_config')
        create_service(software['name'], software['service']) if software.key?('service')
      end
    end

    def create_pre_config(name, version, src_dir, config)
      if config.key?('configure')
        Roles::Software::Configure.new(
          role_dir: @ansible_dir[:role],
          software_name: name,
          software_version: version,
          software_src_dir: src_dir,
          software_configure: config['configure']
        ).create
        @playbook.add("    - #{name}.configure")
      end
    end

    def create_build(name, version, src_dir, config)
      Roles::Software::Build.new(
        role_dir: @ansible_dir[:role],
        software_name: name,
        software_version: version,
        software_src_dir: src_dir,
        build_method: config['method']
      ).create
      @playbook.add("    - #{name}.build")
    end

    def create_post_config(configs)
      configs.each do |config|
        next unless config.key?('type')

        role = case config['type']
               when 'create_file' then Roles::CreateFile.new(role_dir: @ansible_dir[:role], config: config)
               when 'add_to_file' then Roles::AddtoFile.new(role_dir: @ansible_dir[:role], config: config)
               when 'replace_in_file' then Roles::ReplaceinFile.new(role_dir: @ansible_dir[:role], config: config)
               end
        role.create
        @playbook.add("    - #{role.path}")
      end
    end

    def create_service(name, service)
      Roles::Software::Service.new(
        role_dir: @ansible_dir[:role],
        software_name: name,
        service: service
      ).create
      @playbook.add("    - #{name}.service")
    end
  end
end
