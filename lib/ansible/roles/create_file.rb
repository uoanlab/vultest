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
    class CreateFile
      attr_reader :path

      def initialize(args)
        @role_dir = args[:role_dir]
        @config = args[:config]
      end

      def create
        FileUtils.mkdir_p("#{@role_dir}/#{@config['name']}.create.file/files")

        FileUtils.cp_r(
          "#{ANSIBLE_ROLES_TEMPLATE_PATH}/create.file/tasks",
          "#{@role_dir}/#{@config['name']}.create.file"
        )

        FileUtils.cp_r(
          "#{ANSIBLE_ROLES_TEMPLATE_PATH}/create.file/vars",
          "#{@role_dir}/#{@config['name']}.create.file"
        )

        File.open("#{@role_dir}/#{@config['name']}.create.file/vars/main.yml", 'a') do |f|
          f.puts('src: ../files/file')
          f.puts("dest: #{@config['path']}")
          f.puts("group: #{@config['group']}")
          f.puts("owner: #{@config['owner']}")
          f.puts("mode: #{@config['mode']}")
        end

        File.open("#{@role_dir}/#{@config['name']}.create.file/files/file", 'w+') do |f|
          f.puts(@config['content'])
        end

        @path = "#{@config['name']}.create.file"
      end
    end
  end
end
