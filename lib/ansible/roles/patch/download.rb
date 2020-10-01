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
    module Patch
      class Download < Base
        def initialize(args)
          @patch_version = 
            case args[:patch_version].to_s.length
            when 1 then "00#{args[:patch_version]}"
            when 2 then "0#{args[:patch_version]}"
            else args[:patch_version].to_s
            end

          super(
            resource_path: "#{ANSIBLE_ROLES_TEMPLATE_PATH}/patch/download",
            role_path: "#{args[:role_dir]}/#{args[:data]['name']}.patch.#{@patch_version}.download",
            dir: "#{args[:data]['name']}.patch.#{@patch_version}.download",
            data: args[:data]
          )

            @data['url'] = create_url
        end

        private
        def create_url
          url = metadata['software'][@data['name']]['patch']['url']
          url.sub!(
            /{{ core_version }}/,
            "#{@data['version'].to_s.split('.')[0]}.#{@data['version'].to_s.split('.')[1]}"
          )
          url.sub!(
            /{{ core_version }}/,
            "#{@data['version'].to_s.split('.')[0]}#{@data['version'].to_s.split('.')[1]}"
          )
          url.gsub!(/{{ patch_version }}/, @patch_version.to_s)

          url
        end

        def metadata
          YAML.load_file('./metadata.yml')
        end
      end
    end
  end
end
