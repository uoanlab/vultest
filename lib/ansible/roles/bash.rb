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
    module SourceInstall
      module Bash
        class << self
          def create(role_dir, software)
            create_tasks(role_dir, software)
            create_vars(role_dir, software)
          end

          private

          def create_tasks(role_dir, software)
            FileUtils.mkdir_p("#{role_dir}/bash/tasks")
            erb = ERB.new(
              File.read("#{ANSIBLE_ROLES_TEMPLATE_PATH}/bash/tasks/main.yml.erb"),
              trim_mode: 2
            )

            File.open("#{role_dir}/bash/tasks/main.yml", 'w') { |f| f.puts(erb.result(binding)) }
          end

          def create_vars(role_dir, software)
            FileUtils.mkdir_p("#{role_dir}/bash/vars")
            erb = ERB.new(
              File.read("#{ANSIBLE_ROLES_TEMPLATE_PATH}/bash/vars/main.yml.erb"),
              trim_mode: 2
            )

            v = software['version'].split('.')
            version = "#{v[0]}.#{v[1]}"

            patches = v[2].to_i.times.map do |idx|
              idx += 1

              patch_version = "bash#{v[0]}#{v[1]}-"
              patch_version << if idx.to_i < 10 then '00'
                               elsif (idx.to_i >= 10) && (idx.to_i < 100) then '0'
                               end
              patch_version << idx.to_s

              { 'name' => "patch-#{idx}", 'version' => patch_version }
            end

            src_dir = software.fetch('src_dir', '/usr/local/src')
            configure = software.fetch('configure', './configure')
            path =
              if configure.match(/prefix=(.*)/).nil? then '/usr/local/bin/bash'
              else configure.match(/prefix=(.*)/)[1].split(' ')[0]
              end

            File.open("#{role_dir}/bash/vars/main.yml", 'w') { |f| f.puts(erb.result(binding)) }
          end
        end
      end
    end
  end
end
