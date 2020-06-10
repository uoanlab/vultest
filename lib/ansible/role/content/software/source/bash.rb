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
          class Bash < Software::Base
            private

            def create_tasks
              FileUtils.mkdir_p("#{role_dir}/bash/tasks")
              FileUtils.cp_r(
                './data/ansible/roles/source/bash/tasks/main.yml',
                "#{role_dir}/bash/tasks/main.yml"
              )
            end

            def create_vars
              FileUtils.mkdir_p("#{role_dir}/bash/vars")
              File.open("#{role_dir}/bash/vars/main.yml", 'w') do |vars_file|
                vars_file.puts('---')

                vars_file.puts(software_version)
                vars_file.puts(source_path)
                vars_file.puts(configure_command)
                vars_file.puts(src_dir)
                vars_file.puts(user)
              end
            end

            def software_version
              version = software['version'].split('.')
              vars = "version: #{version[0] + '.' + version[1]}\n"
              vars << "patches:\n"
              version[2].to_i.times do |idx|
                idx += 1
                vars << "   - {name: patch-#{idx}, version: bash#{version[0]}#{version[1]}-"
                vars << if idx.to_i < 10 then '00'
                        elsif (idx.to_i >= 10) && (idx.to_i < 100) then '0'
                        end
                vars << "#{idx}}\n"
              end
              vars
            end

            def configure_command
              cmd = 'configure_command: ./configure'
              software.fetch('configure_options', {}).each do |k, v|
                if v == 'yes' then cmd << " --#{k}"
                elsif v == 'no' then next
                else cmd << " --#{k}=#{v}"
                end
              end
              cmd
            end

            def src_dir
              'src_dir: ' << software.fetch('src_dir', '/usr/local/src')
            end

            def source_path
              path = software.fetch('configure_options', nil)
              'source_path: ' << if path.nil? || !path.key?('prefix') then '/usr/local/bin/bash'
                                 elsif path.key?('prefix') then path['prefix']
                                 end
            end
          end
        end
      end
    end
  end
end
