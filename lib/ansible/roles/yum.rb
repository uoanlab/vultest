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

module Ansible
  module Roles
    module Yum
      class << self
        def create(args)
          os_version = args.fetch(:os_version, nil)
          role_dir = args[:role_dir]
          software = args[:software]

          create_tasks(role_dir, software)
          create_vars(role_dir, software, os_version)
        end

        private

        def create_tasks(role_dir, software)
          FileUtils.mkdir_p("#{role_dir}/#{software['name']}/tasks")
          erb = ERB.new(
            File.read("#{ANSIBLE_ROLES_TEMPLATE_PATH}/yum/tasks/main.yml.erb"),
            trim_mode: 2
          )

          name = software['name']
          version = software.fetch('version', nil)
          File.open("#{role_dir}/#{software['name']}/tasks/main.yml", 'w') do |f|
            f.puts(erb.result(binding))
          end
        end

        def create_vars(role_dir, software, os_version)
          FileUtils.mkdir_p("#{role_dir}/#{software['name']}/vars")
          erb = ERB.new(
            File.read("#{ANSIBLE_ROLES_TEMPLATE_PATH}/yum/vars/main.yml.erb"),
            trim_mode: 2
          )

          name = software['name']
          version = software.fetch('version', nil)

          if name == 'mysql'
            os_core_version = os_version.to_s.split('.')[0]
            user = software.fetch('user', 'mysql')
            base_dir = software.fetch('base_dir', '/usr/local/mysql')
            data_dir = software.fetch('data_dir', '/usr/local/mysql/data')
            root_password = software.fetch('root_password', 'Vulnerability123&')
          end

          File.open("#{role_dir}/#{software['name']}/vars/main.yml", 'w') do |f|
            f.puts(erb.result(binding))
          end
        end
      end
    end
  end
end