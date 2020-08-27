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

module Ansible
  module Roles
    class MysqlDatabase
      attr_reader :path

      def initialize(args)
        @role_dir = args[:role_dir]
        @name = args[:config]['name']
        @config = args[:config]['mysql_database']
      end

      def create
        FileUtils.mkdir_p("#{@role_dir}/#{@name}.db")

        FileUtils.cp_r(
          "#{ANSIBLE_ROLES_TEMPLATE_PATH}/database/db/tasks",
          "#{@role_dir}/#{@name}.db"
        )

        FileUtils.cp_r(
          "#{ANSIBLE_ROLES_TEMPLATE_PATH}/database/db/vars",
          "#{@role_dir}/#{@name}.db"
        )

        File.open("#{@role_dir}/#{@name}.db/vars/main.yml", 'a') do |f|
          f.puts("database: #{@config['database']}")
          f.puts("login_user: #{@config['login_user']}")
          f.puts("login_password: #{@config['login_password']}")
          f.puts("config_file: #{@config['config_file']}")
        end

        @path = "#{@name}.db"
      end
    end
  end
end
