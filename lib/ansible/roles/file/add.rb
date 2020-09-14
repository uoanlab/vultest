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
    module File
      class Add
        attr_reader :dir

        def initialize(args)
          @name = args[:config]['name']
          @config = args[:config]['file_add']

          @resource_path = "#{ANSIBLE_ROLES_TEMPLATE_PATH}/file/add"
          @role_path = "#{args[:role_dir]}/#{@name}.file.add"

          @dir = "#{@name}.file.add"
        end

        def create
          FileUtils.mkdir_p(@role_path)

          create_tasks
          create_vars
        end

        private

        def create_tasks
          FileUtils.cp_r("#{@resource_path}/tasks", @role_path)

          insertafter = @config.fetch('insertafter', nil)
          erb = ERB.new(
            ::File.read("#{@resource_path}/tasks/main.yml.erb"),
            trim_mode: 2
          )
          ::File.open("#{@role_path}/tasks/main.yml", 'w') do |f|
            f.puts(erb.result(binding))
          end
        end

        def create_vars
          FileUtils.cp_r("#{@resource_path}/vars", @role_path)

          ::File.open("#{@role_path}/vars/main.yml", 'a') do |f|
            f.puts("dest: #{@config['path']}")
            f.puts("content: \"#{@config['content']}\"")
          end
        end
      end
    end
  end
end
