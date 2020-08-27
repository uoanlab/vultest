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
    class SoftwareConfigure
      attr_reader :path

      def initialize(args)
        @role_dir = args[:role_dir]

        @software = {
          name: args[:software]['name'],
          version: args[:software]['version'],
          src_dir: args[:software].fetch('src_dir', '/usr/local/src'),
          configure: args[:software]['config']['pre_config']['configure']
        }

        metadata = YAML.load_file('./metadata.yml')
        @unzip_file = metadata['softwares'][@software[:name]]['unzip_file']
      end

      def create
        FileUtils.mkdir_p("#{@role_dir}/#{@software[:name]}.configure")

        @unzip_file.gsub!(/{{ version }}/, @software[:version].to_s)
        @unzip_file.gsub!(
          /{{ core_version }}/,
          "#{@software[:version].to_s.split('.')[0]}.#{@software[:version].to_s.split('.')[1]}"
        )

        src_dir = "#{@software[:src_dir]}/#{@unzip_file}"

        create_tasks
        create_vars(src_dir)

        @path = "#{@software[:name]}.configure"
      end

      private

      def create_tasks
        FileUtils.cp_r(
          "#{ANSIBLE_ROLES_TEMPLATE_PATH}/software/configure/tasks",
          "#{@role_dir}/#{@software[:name]}.configure"
        )
      end

      def create_vars(src_dir)
        FileUtils.cp_r(
          "#{ANSIBLE_ROLES_TEMPLATE_PATH}/software/configure/vars",
          "#{@role_dir}/#{@software[:name]}.configure"
        )

        File.open("#{@role_dir}/#{@software[:name]}.configure/vars/main.yml", 'a') do |f|
          f.puts("src_dir: #{src_dir}")
          f.puts("configure: #{@software[:configure]}")
        end
      end
    end
  end
end
