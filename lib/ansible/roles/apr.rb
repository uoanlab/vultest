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
    module SourceInstall
      module APR
        class << self
          def create(role_dir, software)
            create_tasks(role_dir, software)
            create_vars(role_dir, software)
          end

          private

          def create_tasks(role_dir, software)
            FileUtils.mkdir_p("#{role_dir}/apr/tasks")
            erb = ERB.new(
              File.read("#{ANSIBLE_ROLES_TEMPLATE_PATH}/apr/tasks/main.yml.erb"),
              trim_mode: 2
            )

            File.open("#{role_dir}/apr/tasks/main.yml", 'w') do |f|
              f.puts(erb.result(binding))
            end
          end

          def create_vars(role_dir, software)
            FileUtils.mkdir_p("#{role_dir}/apr/vars")
            erb = ERB.new(
              File.read("#{ANSIBLE_ROLES_TEMPLATE_PATH}/apr/vars/main.yml.erb"),
              trim_mode: 2
            )

            version = software['version']
            src_dir = software.fetch('src_dir', '/usr/local/src')
            software_path = SourceInstall.create_software_path(software, '/usr/local/apr')
            configure_command = SourceInstall.create_configure_command(software)

            File.open("#{role_dir}/apr/vars/main.yml", 'w') do |f|
              f.puts(erb.result(binding))
            end
          end
        end
      end
    end
  end
end