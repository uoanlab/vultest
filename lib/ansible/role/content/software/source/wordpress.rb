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

require 'lib/ansible/role/content/software/source/base'

module Ansible
  module Role
    module Content
      module Software
        module Source
          class Wordpress < Base
            private

            def create_tasks
              FileUtils.mkdir_p("#{role_dir}/wordpress/tasks")
              FileUtils.cp_r(
                './data/ansible/roles/source/wordpress/tasks/main.yml',
                "#{role_dir}/wordpress/tasks/main.yml"
              )
            end

            def create_vars
              FileUtils.mkdir_p("#{role_dir}/wordpress/vars")
              File.open("#{role_dir}/wordpress/vars/main.yml", 'w') do |vars_file|
                vars_file.puts('---')
                vars_file.puts("version: #{software['version']}")
                vars_file.puts(src_dir)

                vars_file.puts('document_root: ' << software.fetch('document_root', '/usr/local/apache2/htdocs'))

                vars_file.puts('wordpress_database: ' << software.fetch('wordpress_database', 'wordpressdb'))
                vars_file.puts('wordpress_user: ' << software.fetch('wordpress_user', 'wordpressuser'))
                vars_file.puts('wordpress_password: ' << software.fetch('wordpress_password', 'WordpressPassword123&'))
              end
            end
          end
        end
      end
    end
  end
end
