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

require 'lib/ansible/roles/attack_msf'

require 'lib/ansible/roles/user'

require 'lib/ansible/roles/mysql/database'
require 'lib/ansible/roles/mysql/user'

require 'lib/ansible/roles/file/add'
require 'lib/ansible/roles/file/delete'
require 'lib/ansible/roles/file/create'
require 'lib/ansible/roles/file/copy'
require 'lib/ansible/roles/file/replace'

require 'lib/ansible/roles/command'
require 'lib/ansible/roles/service'

require 'lib/ansible/roles/patch/download'
require 'lib/ansible/roles/patch/install'

require 'lib/ansible/roles/software/source/build'
require 'lib/ansible/roles/software/source/configure'
require 'lib/ansible/roles/software/source/download'

require 'lib/ansible/roles/software/package/install'

require 'lib/ansible/roles/software/nodenv/install'
require 'lib/ansible/roles/software/npm/install'

require 'lib/ansible/roles/software/rbenv/install'
require 'lib/ansible/roles/software/gem/install'

module Ansible
  class Role
    def initialize(playbook, role_path)
      @playbook = playbook
      @role_path = role_path
    end

    def create(host, env_config)
      FileUtils.mkdir_p(@role_path)

      create_attack_method_role(host) if env_config[:attack_method] == 'msf'
      create_users_role(env_config[:users]) unless env_config[:users].empty?
      create_software_role(env_config[:software]) unless env_config[:software].empty?
    end

    private

    def create_attack_method_role(host)
      role = Roles::AttackMSF.new({ role_dir: @role_path, data: host })
      role.create
      @playbook.add("    - #{role.dir}")
    end

    def create_users_role(users)
      users.each do |user|
        role = Roles::User.new({ role_dir: @role_path, data: user })
        role.create
        @playbook.add("    - #{role.dir}")
      end
    end

    def create_software_role(software)
      software.each do |s|
        create_software_role(s['software']) if s.key?('software')
        software_role_detail(s)
      end
    end

    def software_role_detail(software)
      create_software_download_role(software)
      create_patches_role(software)

      configs = software.fetch('config', {})
      if configs.key?('pre_config')
        create_software_configure_role(software) if configs['pre_config'].key?('configure')
        create_software_build_role(software)
      end

      return unless configs.key?('post_config')

      configs['post_config'].each do |config|
        type = config.keys.reject { |key| key == 'name' }[0]

        class_name = type.split('_').map(&:capitalize).join('::')

        role = Object.const_get("Ansible::Roles::#{class_name}").new(
          role_dir: @role_path,
          data: config
        )
        role.create
        @playbook.add("    - #{role.dir}")
      end
    end

    def create_software_download_role(software)
      role =
        case software.fetch('method', nil)
        when 'source'
          Roles::Software::Source::Download.new({ role_dir: @role_path, data: software })
        when 'rbenv'
          Roles::Software::Rbenv::Install.new({ role_dir: @role_path, data: software })
        when 'gem' then Roles::Software::Gem::Install.new({ role_dir: @role_path, data: software })
        when 'nodenv'
          Roles::Software::Nodenv::Install.new({ role_dir: @role_path, data: software })
        when 'npm' then Roles::Software::Npm::Install.new(args)
        else Roles::Software::Package::Install.new({ role_dir: @role_path, data: software })
        end
      role.create
      @playbook.add("    - #{role.dir}")
    end

    def create_patches_role(software)
      return unless software.key?('patch')

      1.upto(software['version'].split('.')[2].to_i) do |version|
        role = Roles::Patch::Download.new(
          role_dir: @role_path,
          data: software,
          patch_version: version
        )
        role.create
        @playbook.add("    - #{role.dir}")

        role = Roles::Patch::Install.new(
          role_dir: @role_path,
          data: software,
          patch_version: version
        )
        role.create
        @playbook.add("    - #{role.dir}")
      end
    end

    def create_software_configure_role(software)
      role = Roles::Software::Source::Configure.new(role_dir: @role_path, data: software)
      role.create
      @playbook.add("    - #{role.dir}")
    end

    def create_software_build_role(software)
      role = Roles::Software::Source::Build.new(role_dir: @role_path, data: software)
      role.create
      @playbook.add("    - #{role.dir}")
    end
  end
end
