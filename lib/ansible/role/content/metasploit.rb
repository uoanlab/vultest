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

require 'lib/ansible/role/content/base'

module Ansible
  module Role
    module Content
      class Metasploit < Base
        attr_reader :os_name, :os_version, :attack_host

        def initialize(args)
          super(role_dir: args[:role_dir])
          @os_name = args[:os_name]
          @os_version = args[:os_version]
          @attack_host = args[:attack_host]
        end

        def create
          FileUtils.mkdir_p("#{role_dir}/metasploit")

          create_tasks
          create_vars
          create_files
        end

        private

        def create_tasks
          FileUtils.mkdir_p("#{role_dir}/metasploit/tasks")

          if os_name == 'ubuntu' && os_version >= '18.04'
            FileUtils.cp_r(
              './data/ansible/roles/metasploit/tasks/latest.yml',
              "#{role_dir}/metasploit/tasks/main.yml"
            )
          else
            FileUtils.cp_r(
              './data/ansible/roles/metasploit/tasks/old.yml',
              "#{role_dir}/metasploit/tasks/main.yml"
            )
          end
        end

        def create_vars
          FileUtils.mkdir_p("#{role_dir}/metasploit/vars")

          FileUtils.cp_r(
            './data/ansible/roles/metasploit/vars/main.yml',
            "#{role_dir}/metasploit/vars/main.yml"
          )
          File.open("#{role_dir}/metasploit/vars/main.yml", 'a') { |vars_file| vars_file.puts("attack_host: #{attack_host}") }
        end

        def create_files
          FileUtils.mkdir_p("#{role_dir}/metasploit/files")

          FileUtils.cp_r(
            './data/ansible/roles/metasploit/files/database.yml',
            "#{role_dir}/metasploit/files/database.yml"
          )
        end
      end
    end
  end
end
