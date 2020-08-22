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

require 'lib/ansible/roles/file/add'
require 'lib/ansible/roles/file/create'
require 'lib/ansible/roles/file/replace'

require 'lib/ansible/roles/patch/download'
require 'lib/ansible/roles/patch/install'

require 'lib/ansible/roles/software/build'
require 'lib/ansible/roles/software/configure'
require 'lib/ansible/roles/software/download'
require 'lib/ansible/roles/software/package'
require 'lib/ansible/roles/software/service'

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
      Roles::AttackToolMSF.new(
        role_dir: @role_path,
        host: host
      ).create
      @playbook.add('    - attack.tool.msf')
    end

    def create_users(users)
      users.each do |user|
        Roles::User.new(
          role_dir: @role_path,
          user_name: user['name'],
          user_shell: user['shell']
        ).create
        @playbook.add("    - #{user['name']}.user")
      end
    end

    def create_softwares(softwares)
      softwares.each do |software|
        create_softwares(software['softwares']) if software.key?('software')

        method = software.fetch('method', '')
        software_version = software.fetch('version', nil)
        patch_version = nil
        if software.key?('patch')
          software_version = "#{software['version'].split('.')[0]}.#{software['version'].split('.')[1]}"
          patch_version = software['version'].split('.')[2]
        end

        create_software_download(
          {
            method: method,
            software_name: software['name'],
            software_version: software_version,
            src_dir: software.fetch('src_dir', nil)
          }
        )

        if software.key?('patch')
          create_patches(
            {
              patch_version: patch_version,
              software_name: software['name'],
              software_version: software_version,
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
                version: software_version,
                src_dir: software['src_dir'],
                configure: configs['pre_config']['configure']
              }
            )
          else
            p 'hello'
          end
        end

        if method == 'source'
          create_build(
            {
              name: software['name'],
              version: software_version,
              src_dir: software['src_dir']
            }
          )
        end

        if configs.key?('post_config')
          configs['post_config'].each do |config|
            next unless config.key?('type')

            role = case config['type']
                   when 'create_file'
                     Roles::File::Create.new(role_dir: @role_path, config: config)
                   when 'add_to_file'
                     Roles::File::Add.new(role_dir: @role_path, config: config)
                   when 'replace_in_file'
                     Roles::File::Replace.new(role_dir: @role_path, config: config)
                   end
            role.create
            @playbook.add("    - #{role.path}")
          end
        end

        create_service(software['name'], software['service']) if software.key?('service')
      end
    end

    def create_software_download(args)
      method = args[:method]
      software = { name: args[:software_name], version: args[:software_version] }
      src_dir = args.fetch(:src_dir, nil)

      case method
      when 'source'
        Roles::Software::Download.new(
          role_dir: @role_path,
          software_name: software[:name],
          software_version: software[:version],
          software_src_dir: src_dir
        ).create
        @playbook.add("    - #{software[:name]}.download")
      else
        Roles::Software::Package.new(
          role_dir: @role_path,
          software_name: software[:name],
          software_version: software[:version]
        ).create
        @playbook.add("    - #{software[:name]}.package")
      end
    end

    def create_patches(args)
      versions = args[:patch_version]
      software = { name: args[:software_name], version: args[:software_version] }
      src_dir = args[:src_dir]

      1.upto(versions.to_i) do |version|
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
      Roles::Software::Configure.new(
        role_dir: @role_path,
        software_name: name,
        software_version: version,
        software_src_dir: src_dir,
        software_configure: configure
      ).create
      @playbook.add("    - #{name}.configure")
    end

    def create_build(args)
      name = args[:name]
      version = args[:version]
      src_dir = args[:src_dir]

      Roles::Software::Build.new(
        role_dir: @role_path,
        software_name: name,
        software_version: version,
        software_src_dir: src_dir
      ).create
      @playbook.add("    - #{name}.make")
    end

    def create_service(name, service)
      Roles::Software::Service.new(
        role_dir: @role_path,
        software_name: name,
        service: service
      ).create
      @playbook.add("    - #{name}.service")
    end
  end
end
