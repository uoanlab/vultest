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

require './lib/ansible/role/content/base'

module Ansible
  module Role
    module Content
      class Metasploit < Base
        attr_reader :attack_host

        def initialize(args)
          super(role_dir: args[:role_dir])
          @attack_host = args[:attack_host]
        end

        def create
          FileUtils.mkdir_p("#{role_dir}/metasploit")
          FileUtils.mkdir_p("#{role_dir}/metasploit/tasks")
          FileUtils.mkdir_p("#{role_dir}/metasploit/vars")
          FileUtils.mkdir_p("#{role_dir}/metasploit/files")
          FileUtils.cp_r(
            './data/ansible/roles/metasploit/tasks/main.yml',
            "#{role_dir}/metasploit/tasks/main.yml"
          )

          FileUtils.cp_r(
            './data/ansible/roles/metasploit/vars/main.yml',
            "#{role_dir}/metasploit/vars/main.yml"
          )
          File.open("#{role_dir}/metasploit/vars/main.yml", 'a') { |vars_file| vars_file.puts("attack_host: #{attack_host}") }

          FileUtils.cp_r(
            './data/ansible/roles/metasploit/files/database.yml',
            "#{role_dir}/metasploit/files/database.yml"
          )
        end
      end
    end
  end
end
