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
    class AttackMSF < Base
      attr_reader :dir

      def initialize(args)
        super(
          resource_path: "#{ANSIBLE_ROLES_TEMPLATE_PATH}/attack.msf",
          role_path: "#{args[:role_dir]}/attack.msf",
          dir: 'attack.msf',
          data: args[:data]
        )
      end

      def create
        super
        create_files
      end

      private

      def create_files
        FileUtils.cp_r("#{@resource_path}/files", @role_path)
      end
    end
  end
end
