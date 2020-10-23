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

module Ansible
  module Roles
    module Software
      module Source
        class Configure < Base
          def initialize(args)
            super(
              resource_path: "#{ANSIBLE_ROLES_TEMPLATE_PATH}/software/source/configure",
              role_path: "#{args[:role_dir]}/#{args[:data]['name']}.configure",
              dir: "#{args[:data]['name']}.configure",
              data: args[:data]
            )

            @data['path'] = "#{args[:data].fetch('src_dir', '/usr/local/src')}/#{create_unzip_file}"
          end

          private

          def create_unzip_file
            unzip_file = metadata['software'][@data['name']]['unzip_file']

            unzip_file.gsub!(/{{ version }}/, @data['version'].to_s)
            unzip_file.gsub!(
              /{{ core_version }}/,
              "#{@data['version'].to_s.split('.')[0]}.#{@data['version'].to_s.split('.')[1]}"
            )

            unzip_file
          end

          def metadata
            YAML.load_file('./metadata.yml')
          end
        end
      end
    end
  end
end
