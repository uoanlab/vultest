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
    class User < Base
      def initialize(args)
        super(
          resource_path: "#{ANSIBLE_ROLES_TEMPLATE_PATH}/user",
          role_path: "#{args[:role_dir]}/#{args[:data]['password']}.user",
          dir: "#{args[:data]['name']}.user",
          data: args[:data]
        )
      end
    end
  end
end
