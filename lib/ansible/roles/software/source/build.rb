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
require 'yaml'

module Ansible
  module Roles
    module Software
      module Source
        class Build
          attr_reader :dir

          def initialize(args)
            @role_dir = args[:role_dir]

            @software = {
              name: args[:software]['name'],
              version: args[:software] ['version']
            }
            @src_dir = args[:software].fetch('src_dir', '/usr/local/src')

            metadata = YAML.load_file('./metadata.yml')
            @unzip_file = metadata['softwares'][@software[:name]]['unzip_file']

            @resource_path = "#{ANSIBLE_ROLES_TEMPLATE_PATH}/software/source/make"
            @role_path = "#{@role_dir}/#{@software[:name]}.make"

            @dir = "#{@software[:name]}.make"
          end

          def create
            FileUtils.mkdir_p(@role_path)

            @unzip_file.gsub!(/{{ version }}/, @software[:version].to_s)
            @unzip_file.gsub!(
              /{{ core_version }}/,
              "#{@software[:version].to_s.split('.')[0]}.#{@software[:version].to_s.split('.')[1]}"
            )
            path = "#{@src_dir}/#{@unzip_file}"

            create_tasks
            create_vars(path)
          end

          private

          def create_tasks
            FileUtils.cp_r("#{@resource_path}/tasks", @role_path)
          end

          def create_vars(path)
            FileUtils.cp_r("#{@resource_path}/vars", @role_path)

            ::File.open("#{@role_path}//vars/main.yml", 'a') { |f| f.puts("path: #{path}") }
          end
        end
      end
    end
  end
end
