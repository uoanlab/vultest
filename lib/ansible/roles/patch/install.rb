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
    module Patch
      class Install
        attr_reader :dir

        def initialize(args)
          @role_dir = args[:role_dir]

          @software = {
            name: args[:software]['name'],
            version: args[:software]['version'],
            src_dir: args[:software].fetch('src_dir', '/usr/local/src')
          }

          metadata = YAML.load_file('./metadata.yml')
          @software_dir = metadata['software'][@software[:name]]['unzip_file']
          @patch_name = metadata['software'][@software[:name]]['patch']['unzip_file']
          @patch_version = args[:patch_version]

          @resource_path = "#{ANSIBLE_ROLES_TEMPLATE_PATH}/patch/install"
        end

        def create
          @software_dir.gsub!(
            /{{ core_version }}/,
            "#{@software[:version].to_s.split('.')[0]}.#{@software[:version].to_s.split('.')[1]}"
          )

          @patch_version =
            case @patch_version.to_s.length
            when 1 then "00#{@patch_version}"
            when 2 then "0#{@patch_version}"
            else @patch_version.to_s
            end
          @patch_name.gsub!(
            /{{ core_version }}/,
            "#{@software[:version].to_s.split('.')[0]}#{@software[:version].to_s.split('.')[1]}"
          )
          @patch_name.gsub!(/{{ patch_version }}/, @patch_version.to_s)

          @role_path = "#{@role_dir}/#{@software[:name]}.patch.#{@patch_version}.install"
          @dir = "#{@software[:name]}.patch.#{@patch_version}.install"

          FileUtils.mkdir_p(@role_path)
          create_tasks
          create_vars
        end

        private

        def create_tasks
          FileUtils.cp_r("#{@resource_path}/tasks", @role_path)
        end

        def create_vars
          FileUtils.cp_r("#{@resource_path}/vars", @role_path)

          ::File.open("#{@role_path}/vars/main.yml", 'a') do |f|
            f.puts("src_dir: #{@software[:src_dir]}")
            f.puts("software_dir: #{@software_dir}")
            f.puts("patch_name: #{@patch_name}")
          end
        end
      end
    end
  end
end
