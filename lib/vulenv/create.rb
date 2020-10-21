# Copyright [2020] [University of Aizu]
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Vulenv
  class Create
    attr_reader :vagrant, :ansible

    def initialize(args)
      @env_dir = args[:env_dir]
      @attack_vector = args[:vulnerability]['attack_vector']

      env_config = args[:env_config]
      @os = {
        name: env_config['os']['name'],
        version: env_config['os']['version']
      }
      @users = env_config.fetch('user', [])
      @software = env_config.fetch('software', [])

      @vagrant = nil
      @ansible = nil
    end

    def exec
      @vagrant = prepare_vagrant
      vagrant.create

      @ansible = prepare_ansible
      ansible.create
    end

    private

    def prepare_vagrant
      @vagrant = Vagrant::Core.new(
        os_name: @os[:name],
        os_version: @os[:version],
        host: '192.168.177.177',
        env_dir: @env_dir
      )
    end

    def prepare_ansible
      @software = @software.map { |software| software }

      attack_method =
        case @attack_vector
        when 'local' then 'msf'
        end

      Ansible::Core.new(
        env_dir: @env_dir,
        host: '192.168.177.177',
        os_name: @os[:name],
        users: @users,
        software: @software,
        attack_method: attack_method
      )
    end
  end
end
