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
require 'yaml'

require 'lib/ansible/roles/base'

module Ansible
  module Roles
    module Software
      module Source
        class Build < Base
          def initialize(args)
            super(
              resource_path: "#{ANSIBLE_ROLES_TEMPLATE_PATH}/software/source/make",
              role_path: "#{args[:role_dir]}/#{args[:data]['name']}.make",
              dir: "#{args[:data]['name']}.make",
              data: args[:data]
            )

            software = {
              name: args[:data]['name'],
              version: args[:data] ['version']
            }
            metadata = YAML.load_file('./metadata.yml')
            unzip_file = metadata['software'][software[:name]]['unzip_file']

            unzip_file.gsub!(/{{ version }}/, software[:version].to_s)
            unzip_file.gsub!(
              /{{ core_version }}/,
              "#{software[:version].to_s.split('.')[0]}.#{software[:version].to_s.split('.')[1]}"
            )

            @data['path'] = "#{args[:data].fetch('src_dir', '/usr/local/src')}/#{unzip_file}"
          end
        end
      end
    end
  end
end
