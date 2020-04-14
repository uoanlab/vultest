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

require 'bundler/setup'
require 'fileutils'

module Ansible
  class Base
    attr_reader :ansible_dir

    def initialize(args)
      @ansible_dir =
        {
          base: "#{args[:env_dir]}/ansible",
          hosts: "#{args[:env_dir]}/ansible/hosts",
          playbook: "#{args[:env_dir]}/ansible/playbook",
          roles: "#{args[:env_dir]}/ansible/roles"
        }
    end

    def create
      ansible_dir.each { |_key, value| FileUtils.mkdir_p(value.to_s) }
      create_hosts
      create_roles
      create_playbook
    end

    private

    def create_hosts
      raise NotImplementedError
    end

    def create_roles
      raise NotImplementedError
    end

    def create_playbook
      raise NotImplementedError
    end
  end
end
