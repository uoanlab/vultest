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
    class AttackToolMSF
      def initialize(args)
        @role_dir = args[:role_dir]
        @host = args[:host]
      end

      def create
        FileUtils.mkdir_p("#{@role_dir}/attack.tool.msf")

        FileUtils.cp_r(
          "#{ANSIBLE_ROLES_TEMPLATE_PATH}/attack.tool.msf/tasks",
          "#{@role_dir}/attack.tool.msf"
        )

        FileUtils.cp_r(
          "#{ANSIBLE_ROLES_TEMPLATE_PATH}/attack.tool.msf/vars",
          "#{@role_dir}/attack.tool.msf"
        )

        FileUtils.cp_r(
          "#{ANSIBLE_ROLES_TEMPLATE_PATH}/attack.tool.msf/files",
          "#{@role_dir}/attack.tool.msf"
        )

        File.open("#{@role_dir}/attack.tool.msf/vars/main.yml", 'a') do |f|
          f.puts("attack_host: #{@host}")
        end
      end
    end
  end
end
