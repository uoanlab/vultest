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
    module MySQL
      class << self
        def create(role_dir, software)
          create_tasks(role_dir)
          create_vars(role_dir, software)
        end

        private

        def create_tasks(role_dir)
          FileUtils.mkdir_p("#{role_dir}/mysql/tasks")
          erb = ERB.new(
            File.read("#{ANSIBLE_ROLES_TEMPLATE_PATH}/mysql/tasks/main.yml.erb"),
            trim_mode: 2
          )

          File.open("#{role_dir}/mysql/tasks/main.yml", 'w') do |f|
            f.puts(erb.result(binding))
          end
        end

        def create_vars(role_dir, software)
          FileUtils.mkdir_p("#{role_dir}/mysql/vars")
          erb = ERB.new(
            File.read("#{ANSIBLE_ROLES_TEMPLATE_PATH}/mysql/vars/main.yml.erb"),
            trim_mode: 2
          )

          version = software['version']

          user = software.fetch('user', 'root')

          base_dir = software.fetch('base_dir', '/var/lib/mysql')
          data_dir = software.fetch('data_dir', '/var/lib/mysql/data')
          database_root_password = software.fetch('root_password', 'Vulnerability123&')

          File.open("#{role_dir}/mysql/vars/main.yml", 'w') do |f|
            f.puts(erb.result(binding))
          end
        end
      end
    end
  end
end
