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
    module Content
      class << self
        def create(args)
          role_dir = args[:role_dir]
          content = args[:content]

          if Dir.exist?("#{BASE_CONFIG['vultest_db_path']}/data/#{content}/files")
            create_files(role_dir, content)
          end

          if Dir.exist?("#{BASE_CONFIG['vultest_db_path']}/data/#{content}/vars")
            create_vars(role_dir, content)
          end

          create_tasks(role_dir, content)
        end

        private

        def create_files(role_dir, content)
          FileUtils.mkdir_p("#{role_dir}/content/files")

          db_path = BASE_CONFIG['vultest_db_path']
          Dir.glob("#{db_path}/data/#{content}/files/*") do |path|
            file_path = path.split('/')
            FileUtils.cp_r(
              "#{db_path}/data/#{content}/files/#{file_path[file_path.size - 1]}",
              "#{role_dir}/content/files/#{file_path[file_path.size - 1]}"
            )
          end
        end

        def create_tasks(role_dir, content)
          FileUtils.mkdir_p("#{role_dir}/content/tasks")

          FileUtils.cp_r(
            "#{BASE_CONFIG['vultest_db_path']}/data/#{content}/tasks/main.yml",
            "#{role_dir}/content/tasks/main.yml"
          )
        end

        def create_vars(role_dir, content)
          FileUtils.mkdir_p("#{role_dir}/content/vars")

          FileUtils.mkdir_p("#{role_dir}/content/vars")
          FileUtils.cp_r(
            "#{BASE_CONFIG['vultest_db_path']}/data/#{content}/vars/main.yml",
            "#{role_dir}/content/vars/main.yml"
          )
        end
      end
    end
  end
end
