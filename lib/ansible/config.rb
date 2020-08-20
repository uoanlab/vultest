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
  class Config
    def initialize(ansible_path)
      @ansible_path = ansible_path
    end

    def create
      FileUtils.mkdir_p(@ansible_path)

      FileUtils.cp(ANSIBLE_CONFIG_TEMPLATE_PATH, "#{@ansible_path}/ansible.cfg")
    end
  end
end
