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

require './lib/vm/base'
require './lib/environment/attack_env'

require './lib/vagrant/command'
require './lib/vagrant/vagrantfile/attack_env'
require './lib/ansible/attack_env'

module VM
  module AttackEnv
    class AutoRemoteHost < ::VM::Base
      attr_reader :host, :attack_config

      def initialize(args)
        super(env_dir: args[:env_dir])
        @host = args[:host]
        @attack_config = args[:attack_config]
        @operating_environment = Environment::AttackEnv.new(
          host: args[:host],
          user: args[:user],
          password: args[:password],
          attack_config: args[:attack_config]
        )
      end

      private

      def create_msg
        'Create an attack environment'
      end

      def destroy_msg
        "Destroy attack_dir(#{env_dir})"
      end

      def prepare_vagrant
        Vagrant::Vagrantfile::AttackEnv.new(env_dir: env_dir, host: host).create

        @vagrant = Vagrant::Command.new
      end

      def prepare_ansible
        Ansible::AttackEnv.new(env_dir: env_dir, host: host).create
      end

      def start_vm?
        Dir.chdir(env_dir) { @error[:flag] = !vagrant.start_up? }
        error[:flag]
      end
    end
  end
end
