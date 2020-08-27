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

require 'lib/ansible/roles/user'

require 'lib/ansible/roles/mysql_database'
require 'lib/ansible/roles/mysql_user'

require 'lib/ansible/roles/file_add'
require 'lib/ansible/roles/file_delete'
require 'lib/ansible/roles/file_create'
require 'lib/ansible/roles/file_copy'
require 'lib/ansible/roles/file_replace'

require 'lib/ansible/roles/command'
require 'lib/ansible/roles/service'

require 'lib/ansible/roles/patch_download'
require 'lib/ansible/roles/patch_install'
require 'lib/ansible/roles/software_build'
require 'lib/ansible/roles/software_configure'
require 'lib/ansible/roles/software_download'
require 'lib/ansible/roles/software_package'

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
        create_software(software)
      end
    end

    def create_software(software)
      create_software_download(software)
      create_patches(software)

      configs = software.fetch('config', {})
      if configs.key?('pre_config')
        create_software_configure(software) if configs['pre_config'].key?('configure')
        create_software_build(software)
      end

      return unless configs.key?('post_config')

      configs['post_config'].each do |config|
        type = config.keys.reject { |key| key == 'name' }[0]

        class_name = type.split('_').map(&:capitalize).join

        role = Object.const_get("Ansible::Roles::#{class_name}").new(
          role_dir: @role_path,
          config: config
        )
        role.create
        @playbook.add("    - #{role.path}")
      end
    end

    def create_software_download(software)
      role =
        case software.fetch('method', nil)
        when 'source'
          Roles::SoftwareDownload.new(role_dir: @role_path, software: software)
        else
          Roles::SoftwarePackage.new(role_dir: @role_path, software: software)
        end
      role.create
      @playbook.add("    - #{role.path}")
    end

    def create_patches(software)
      return unless software.key?('patch')

      1.upto(software['version'].split('.')[2].to_i) do |version|
        role = Roles::PatchDownload.new(
          role_dir: @role_path,
          software: software,
          patch_version: version
        )
        role.create
        @playbook.add("    - #{role.path}")

        role = Roles::PatchInstall.new(
          role_dir: @role_path,
          software: software,
          patch_version: version
        )
        role.create
        @playbook.add("    - #{role.path}")
      end
    end

    def create_software_configure(software)
      role = Roles::SoftwareConfigure.new(role_dir: @role_path, software: software)
      role.create
      @playbook.add("    - #{role.path}")
    end

    def create_software_build(software)
      role = Roles::SoftwareBuild.new(role_dir: @role_path, software: software)
      role.create
      @playbook.add("    - #{role.path}")
    end
  end
end
