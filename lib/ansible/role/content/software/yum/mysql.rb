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
require 'bundler/setup'
require 'fileutils'

require 'lib/ansible/role/content/software/base'

module Ansible
  module Role
    module Content
      module Software
        module Yum
          class MySQL < Software::Base
            attr_reader :os_core_version

            def initialize(args)
              super(role_dir: args[:role_dir], software: args[:software])
              @os_core_version = args[:os_version].to_s.split('.')[0]
            end

            private

            def create_tasks
              FileUtils.mkdir_p("#{role_dir}/#{software['name']}/tasks")
              FileUtils.cp_r('./data/ansible/roles/yum/mysql/tasks/main.yml', "#{role_dir}/#{software['name']}/tasks/main.yml")
            end

            def create_vars
              FileUtils.mkdir_p("#{role_dir}/#{software['name']}/vars")
              File.open("#{role_dir}/#{software['name']}/vars/main.yml", 'w') do |vars_file|
                vars_file.puts('---')
                vars_file.puts("os_core_version: #{os_core_version}")
                vars_file.puts("version: #{software['version']}")

                vars_file.puts('user: ' << software.fetch('user', 'mysql'))
                vars_file.puts('base_dir: ' << software.fetch('base_dir', '/usr/local/mysql'))
                vars_file.puts('data_dir: ' << software.fetch('data_dir', '/usr/local/mysql/data'))
                vars_file.puts('root_password: ' << software.fetch('root_password', 'Vulnerability123&'))
              end
            end
          end
        end
      end
    end
  end
end
