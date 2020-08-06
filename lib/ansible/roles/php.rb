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
      module PHP
        class << self
          def create(role_dir, software)
            create_tasks(role_dir)
            create_vars(role_dir, software)
          end

          private

          def create_tasks(role_dir)
            FileUtils.mkdir_p("#{role_dir}/php/tasks")
            erb = ERB.new(
              File.read("#{ANSIBLE_ROLES_TEMPLATE_PATH}/php/tasks/main.yml.erb"),
              trim_mode: 2
            )

            File.open("#{role_dir}/php/tasks/main.yml", 'w') do |f|
              f.puts(erb.result(binding))
            end
          end

          def create_vars(role_dir, software)
            FileUtils.mkdir_p("#{role_dir}/php/vars")
            erb = ERB.new(
              File.read("#{ANSIBLE_ROLES_TEMPLATE_PATH}/php/vars/main.yml.erb"),
              trim_mode: 2
            )

            version = software['version']
            src_dir = software.fetch('src_dir', '/usr/local/src')
            configure = software.fetch('configure', './configure')

            path =
              if configure.match(/prefix=(.*)/).nil? then '/usr/local/bin/php'
              else configure.match(/prefix=(.*)/)[1].split(' ')[0]
              end

            File.open("#{role_dir}/php/vars/main.yml", 'w') do |f|
              f.puts(erb.result(binding))
            end
          end
        end
      end
    end
  end
end
