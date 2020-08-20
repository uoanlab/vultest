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
    class SoftwareService
      def initialize(args)
        @role_dir = args[:role_dir]
        @software_name = args[:software_name]
        @service = args[:service]
      end

      def create
        FileUtils.mkdir_p("#{@role_dir}/#{@software_name}.service")

        FileUtils.cp_r(
          "#{ANSIBLE_ROLES_TEMPLATE_PATH}/software.service/tasks",
          "#{@role_dir}/#{@software_name}.service"
        )

        FileUtils.cp_r(
          "#{ANSIBLE_ROLES_TEMPLATE_PATH}/software.service/vars",
          "#{@role_dir}/#{@software_name}.service"
        )

        File.open("#{@role_dir}/#{@software_name}.service/vars/main.yml", 'a') do |f|
          f.puts("command: #{@service['command']}") if @service.key?('command')
          f.puts("service_name: #{@service['linux_daemon']}") if @service.key?('linux_daemon')
        end
      end
    end
  end
end
