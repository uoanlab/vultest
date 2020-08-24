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
    class User
      attr_reader :path

      def initialize(args)
        @role_dir = args[:role_dir]

        @user = {
          name: args[:user_name],
          shell: args[:user_shell]
        }
      end

      def create
        FileUtils.mkdir_p("#{@role_dir}/#{@user[:name]}.user")

        FileUtils.cp_r(
          "#{ANSIBLE_ROLES_TEMPLATE_PATH}/user/tasks",
          "#{@role_dir}/#{@user[:name]}.user"
        )

        FileUtils.cp_r(
          "#{ANSIBLE_ROLES_TEMPLATE_PATH}/user/vars",
          "#{@role_dir}/#{@user[:name]}.user"
        )

        ::File.open("#{@role_dir}/#{@user[:name]}.user/vars/main.yml", 'a') do |f|
          f.puts("name: #{@user[:name]}")
          f.puts("shell: #{@user[:shell]}")
        end

        @path = "#{@user[:name]}.user"
      end
    end
  end
end
