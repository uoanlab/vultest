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
    module Patch
      class Install < Base
        def initialize(args)
          @patch_version =
            case args[:patch_version].to_s.length
            when 1 then "00#{args[:patch_version]}"
            when 2 then "0#{args[:patch_version]}"
            else args[:patch_version].to_s
            end

          super(
            resource_path: "#{ANSIBLE_ROLES_TEMPLATE_PATH}/patch/install",
            role_path: "#{args[:role_dir]}/#{args[:data]['name']}.patch.#{@patch_version}.install",
            dir: "#{args[:data]['name']}.patch.#{@patch_version}.install",
            data: args[:data]
          )

          @data['software_dir'] = create_software_dir
          @data['patch_name'] = create_patch_name
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

        def create_software_dir
          metadata['software'][@data['name']]['unzip_file'].gsub!(
            /{{ core_version }}/,
            "#{@data['version'].to_s.split('.')[0]}.#{@data['version'].to_s.split('.')[1]}"
          )
        end

        def create_patch_name
          metadata['software'][@data['name']]['patch']['unzip_file'].gsub!(
            /{{ core_version }}/,
            "#{@data['version'].to_s.split('.')[0]}#{@data['version'].to_s.split('.')[1]}"
          ).gsub!(
            /{{ patch_version }}/,
            @patch_version.to_s
          )
        end

        def metadata
          YAML.load_file('./metadata.yml')
        end
      end
    end
  end
end
