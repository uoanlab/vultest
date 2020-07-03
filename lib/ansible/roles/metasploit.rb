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
    module Metasploit
      class << self
        def create(args)
          role_dir = args[:role_dir]
          host = args[:host]
          create_files(role_dir)
          create_tasks(role_dir)
          create_vars(role_dir, host)
        end

        private

        def create_files(role_dir)
          FileUtils.mkdir_p("#{role_dir}/metasploit/files")
          erb = ERB.new(
            File.read("#{ANSIBLE_ROLES_TEMPLATE_PATH}/metasploit/files/database.yml.erb"), trim_mode: 2
          )

          File.open("#{role_dir}/metasploit/files/database.yml", 'w') do |f|
            f.puts(erb.result(binding))
          end
        end

        def create_tasks(role_dir)
          FileUtils.mkdir_p("#{role_dir}/metasploit/tasks")
          erb = ERB.new(
            File.read("#{ANSIBLE_ROLES_TEMPLATE_PATH}/metasploit/tasks/main.yml.erb"), trim_mode: 2
          )

          File.open("#{role_dir}/metasploit/tasks/main.yml", 'w') do |f|
            f.puts(erb.result(binding))
          end
        end

        def create_vars(role_dir, host)
          FileUtils.mkdir_p("#{role_dir}/metasploit/vars")
          erb = ERB.new(
            File.read("#{ANSIBLE_ROLES_TEMPLATE_PATH}/metasploit/vars/main.yml.erb"), trim_mode: 2
          )

          attack_host = host
          File.open("#{role_dir}/metasploit/vars/main.yml", 'w') do |f|
            f.puts(erb.result(binding))
          end
        end
      end
    end
  end
end
