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
      module Wordpress
        class << self
          def create(role_dir, software)
            create_tasks(role_dir, software)
            create_vars(role_dir, software)
          end

          private

          def create_tasks(role_dir, software)
            FileUtils.mkdir_p("#{role_dir}/wordpress/tasks")
            erb = ERB.new(
              File.read("#{ANSIBLE_ROLES_TEMPLATE_PATH}/wordpress/tasks/main.yml.erb"),
              trim_mode: 2
            )

            File.open("#{role_dir}/wordpress/tasks/main.yml", 'w') do |f|
              f.puts(erb.result(binding))
            end
          end

          def create_vars(role_dir, software)
            FileUtils.mkdir_p("#{role_dir}/wordpress/vars")
            erb = ERB.new(
              File.read("#{ANSIBLE_ROLES_TEMPLATE_PATH}/wordpress/vars/main.yml.erb"),
              trim_mode: 2
            )

            version = software['version']
            src_dir = software.fetch('src_dir', '/usr/local/src')
            document_root = software.fetch('document_root', '/usr/local/apache2/htdocs')

            database = software.fetch('database', {})
            wordpress_database = database.fetch('name', 'wordpressdb')
            wordpress_user = database.fetch('user_name', 'wordpressuser')
            wordpress_password = database.fetch('user_password', 'wordpresspassword')

            File.open("#{role_dir}/wordpress/vars/main.yml", 'w') do |f|
              f.puts(erb.result(binding))
            end
          end
        end
      end
    end
  end
end
