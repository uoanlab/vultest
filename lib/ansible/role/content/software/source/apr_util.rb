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
        module Source
          class APRUtil < Software::Base
            private

            def create_tasks
              FileUtils.mkdir_p("#{role_dir}/apr-util/tasks")
              FileUtils.cp_r(
                './data/ansible/roles/source/apr-util/tasks/main.yml',
                "#{role_dir}/apr-util/tasks/main.yml"
              )
            end

            def create_vars
              FileUtils.mkdir_p("#{role_dir}/apr-util/vars")
              File.open("#{role_dir}/apr-util/vars/main.yml", 'w') do |vars_file|
                vars_file.puts('---')
                vars_file.puts("version: #{software['version']}")
                vars_file.puts(source_path)
                vars_file.puts(configure_command)
                vars_file.puts(src_dir)
                vars_file.puts(user)
              end
            end

            def configure_command
              cmd = 'configure_command: ./configure'
              software.fetch('configure_options', {}).each { |k, v| cmd << " --#{k}=#{v}" }
              cmd
            end

            def src_dir
              'src_dir: ' << software.fetch('src_dir', '/usr/local/src')
            end

            def source_path
              path = software.fetch('configure_options', nil)
              'source_path: ' << if path.nil? || !path.key?('prefix') then '/usr/local/apr'
                                 elsif path.key?('prefix') then path['prefix']
                                 end
            end
          end
        end
      end
    end
  end
end