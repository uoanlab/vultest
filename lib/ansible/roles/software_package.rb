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
    class SoftwarePackage
      attr_reader :path

      def initialize(args)
        @role_dir = args[:role_dir]

        @software = {
          name: args[:software]['name'],
          version: args[:software]['version']
        }
      end

      def create
        FileUtils.mkdir_p("#{@role_dir}/#{@software[:name]}.package")

        create_tasks
        create_vars

        @path = "#{@software[:name]}.package"
      end

      private

      def create_tasks
        FileUtils.cp_r(
          "#{ANSIBLE_ROLES_TEMPLATE_PATH}/software/package/tasks",
          "#{@role_dir}/#{@software[:name]}.package"
        )
      end

      def create_vars
        FileUtils.cp_r(
          "#{ANSIBLE_ROLES_TEMPLATE_PATH}/software/package/vars",
          "#{@role_dir}/#{@software[:name]}.package"
        )

        File.open("#{@role_dir}/#{@software[:name]}.package/vars/main.yml", 'a') do |f|
          f.puts("name: #{@software[:name]}")
          f.puts("version: #{@software[:version]}") unless @software[:version].nil?
        end
      end
    end
  end
end
