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

require 'lib/ansible/roles/attack_tool_msf'

require 'lib/ansible/roles/database/user'

require 'lib/ansible/roles/file/add'
require 'lib/ansible/roles/file/create'
require 'lib/ansible/roles/file/copy'
require 'lib/ansible/roles/file/replace'

require 'lib/ansible/roles/patch/download'
require 'lib/ansible/roles/patch/install'

require 'lib/ansible/roles/software/build'
require 'lib/ansible/roles/software/configure'
require 'lib/ansible/roles/software/download'
require 'lib/ansible/roles/software/package'

require 'lib/ansible/roles/command'

require 'lib/ansible/roles/service'

require 'lib/ansible/roles/user'

module Ansible
  class Role
    def initialize(playbook, role_path)
      @playbook = playbook
      @role_path = role_path
    end

    def create(host, env_config)
      FileUtils.mkdir_p(@role_path)

      create_attack_tool(host) if env_config[:attack_tool] == 'msf'
      create_users(env_config[:users]) unless env_config[:users].empty?
      create_softwares(env_config[:softwares]) unless env_config[:softwares].empty?
    end

    private

    def create_attack_tool(host)
      role = Roles::AttackToolMSF.new(
        role_dir: @role_path,
        host: host
      )
      role.create
      @playbook.add("    - #{role.path}")
    end

    def create_users(users)
      users.each do |user|
        role = Roles::User.new(
          role_dir: @role_path,
          user_name: user['name'],
          user_shell: user['shell']
        )
        role.create
        @playbook.add("    - #{role.path}")
      end
    end

    def create_softwares(softwares)
      softwares.each do |software|
        create_softwares(software['softwares']) if software.key?('softwares')

        create_software_download(
          {
            method: software.fetch('method', nil),
            software_name: software['name'],
            software_version: software['version'],
            src_dir: software.fetch('src_dir', nil)
          }
        )

        if software.key?('patch')
          create_patches(
            {
              software_name: software['name'],
              software_version: software['version'],
              src_dir: software['src_dir']
            }
          )
        end

        configs = software.fetch('config', {})
        if configs.key?('pre_config')

          if configs['pre_config'].key?('configure')
            create_configure(
              {
                name: software['name'],
                version: software['version'],
                src_dir: software['src_dir'],
                configure: configs['pre_config']['configure']
              }
            )
          end
          create_build(
            {
              name: software['name'],
              version: software['version'],
              src_dir: software['src_dir']
            }
          )
        end

        next unless configs.key?('post_config')

        configs['post_config'].each do |config|
          role = if config.key?('file_create')
                   Roles::File::Create.new(role_dir: @role_path, name: config['name'], config: config['file_create'])
                 elsif config.key?('file_add')
                   Roles::File::Add.new(role_dir: @role_path, name: config['name'], config: config['file_add'])
                 elsif config.key?('file_copy')
                   Roles::File::Copy.new(role_dir: @role_path, name: config['name'], config: config['file_copy'])
                 elsif config.key?('file_replace')
                   Roles::File::Replace.new(role_dir: @role_path, name: config['name'], config: config['file_replace'])
                 elsif config.key?('command')
                   Roles::Command.new(role_dir: @role_path, name: config['name'], config: config)
                 elsif config.key?('service')
                   Roles::Service.new(role_dir: @role_path, name: config['name'], config: config)
                 elsif config.key?('db_user')
                   Roles::Database::User.new(role_dir: @role_path, name: config['name'], config: config['db_user'])
                  end
          role.create
          @playbook.add("    - #{role.path}")
        end
      end
    end

    def create_software_download(args)
      method = args[:method]
      software = { name: args[:software_name], version: args[:software_version] }
      src_dir = args.fetch(:src_dir, nil)

      role = case method
             when 'source'
               Roles::Software::Download.new(
                 role_dir: @role_path,
                 software_name: software[:name],
                 software_version: software[:version],
                 software_src_dir: src_dir
               )
             else
               Roles::Software::Package.new(
                 role_dir: @role_path,
                 software_name: software[:name],
                 software_version: software[:version]
               )
              end
      role.create
      @playbook.add("    - #{role.path}")
    end

    def create_patches(args)
      software = { name: args[:software_name], version: args[:software_version] }
      src_dir = args[:src_dir]

      1.upto(software[:version].split('.')[2].to_i) do |version|
        role = Roles::Patch::Download.new(
          role_dir: @role_path,
          software_name: software[:name],
          software_version: software[:version],
          software_src_dir: src_dir,
          patch_version: version
        )
        role.create
        @playbook.add("    - #{role.path}")

        role = Roles::Patch::Install.new(
          role_dir: @role_path,
          software_name: software[:name],
          software_version: software[:version],
          software_src_dir: src_dir,
          patch_version: version
        )
        role.create
        @playbook.add("    - #{role.path}")
      end
    end

    def create_configure(args)
      name = args[:name]
      version = args[:version]
      src_dir = args[:src_dir]
      configure = args[:configure]
      role = Roles::Software::Configure.new(
        role_dir: @role_path,
        software_name: name,
        software_version: version,
        software_src_dir: src_dir,
        software_configure: configure
      )
      role.create
      @playbook.add("    - #{role.path}")
    end

    def create_build(args)
      name = args[:name]
      version = args[:version]
      src_dir = args[:src_dir]

      role = Roles::Software::Build.new(
        role_dir: @role_path,
        software_name: name,
        software_version: version,
        software_src_dir: src_dir
      )
      role.create
      @playbook.add("    - #{role.path}")
    end
  end
end
