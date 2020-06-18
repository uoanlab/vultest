# Copyright [2019] [University of Aizu]
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

require 'lib/ansible/role/content/base'

module Ansible
  module Role
    module Content
      class Content < Base
        attr_reader :db_path, :cve, :content

        def initialize(args)
          super(role_dir: args[:role_dir])

          @db_path = args[:db_path]
          @cve = args[:cve]
          @content = args[:content]
        end

        def create
          create_tasks
          create_vars if Dir.exist?("#{db_path}/data/#{content}/vars")
          create_files if Dir.exist?("#{db_path}/data/#{content}/files")
          create_handlers if Dir.exist?("#{db_path}/data/#{content}/handlers")
        end

        private

        def create_tasks
          FileUtils.mkdir_p("#{role_dir}/#{cve}/tasks")
          FileUtils.cp_r(
            "#{db_path}/data/#{content}/tasks/main.yml",
            "#{role_dir}/#{cve}/tasks/main.yml"
          )
        end

        def create_vars
          FileUtils.mkdir_p("#{role_dir}/#{cve}/vars")
          FileUtils.cp_r(
            "#{db_path}/data/#{content}/vars/main.yml",
            "#{role_dir}/#{cve}/vars/main.yml"
          )
        end

        def create_files
          FileUtils.mkdir_p("#{role_dir}/#{cve}/files")
          Dir.glob("#{db_path}/data/#{content}/files/*") do |path|
            file_path = path.split('/')
            FileUtils.cp_r(
              "#{db_path}/data/#{content}/files/#{file_path[file_path.size - 1]}",
              "#{role_dir}/#{cve}/files/#{file_path[file_path.size - 1]}"
            )
          end
        end

        def create_handlers
          FileUtils.mkdir_p("#{role_dir}/#{cve}/handlers")
          FileUtils.cp_r(
            "#{db_path}/data/#{content}/handlers/main.yml",
            "#{role_dir}/#{cve}/handlers/main.yml"
          )
        end
      end
    end
  end
end
