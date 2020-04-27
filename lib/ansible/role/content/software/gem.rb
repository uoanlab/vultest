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
        class Gem < Base
          private

          def create_tasks
            FileUtils.mkdir_p("#{role_dir}/#{software['name']}/tasks")
            FileUtils.cp_r(
              './data/ansible/roles/gem/tasks/main.yml',
              "#{role_dir}/#{software['name']}/tasks/main.yml"
            )
          end

          def create_vars
            FileUtils.mkdir_p("#{role_dir}/#{software['name']}/vars")
            File.open("#{role_dir}/#{software['name']}/vars/main.yml", 'w') do |vars_file|
              vars_file.puts('---')
              vars_file.puts("name: #{software['name']}")
              vars_file.puts("version: #{software['version']}")
              vars_file.puts(option_user)
            end
          end
        end
      end
    end
  end
end
