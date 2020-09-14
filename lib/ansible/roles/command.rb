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
    class Command
      attr_reader :dir

      def initialize(args)
        @name = args[:config]['name']
        @config = args[:config]

        @resource_path = "#{ANSIBLE_ROLES_TEMPLATE_PATH}/command"
        @role_path = "#{args[:role_dir]}/#{@name}.command"

        @dir = "#{@name}.command"
      end

      def create
        FileUtils.mkdir_p(@role_path)

        create_tasks
        create_vars
      end

      private

      def create_tasks
        FileUtils.cp_r("#{@resource_path}/tasks", @role_path)
      end

      def create_vars
        FileUtils.cp_r("#{@resource_path}/vars", @role_path)

        ::File.open("#{@role_path}/vars/main.yml", 'a') do |f|
          f.puts("command: #{@config['command']}")
        end
      end
    end
  end
end
