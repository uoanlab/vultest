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
require 'lib/ansible/core'
require 'lib/vagrant/core'

module Attack
  class Create
    attr_reader :vagrant, :ansible

    def initialize(args)
      @env_dir = args[:env_dir]

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
        os_name: 'ubuntu',
        os_version: '18.04',
        vagrant_img_box: 'ubuntu/bionic64',
        host: '192.168.77.77',
        env_dir: @env_dir
      )
    end

    def prepare_ansible
      Ansible::Core.new(
        env_dir: @env_dir,
        os_name: 'ubuntu',
        host: '192.168.77.77',
        attack_method: 'msf'
      )
    end
  end
end
