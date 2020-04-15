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

require './lib/vm/control/base'
require './lib/vagrant/command'
require './lib/vagrant/vagrantfile/vulenv/linux'
require './lib/vagrant/vagrantfile/vulenv/windows'
require './lib/ansible/vulenv'

module VM
  module Control
    class Vulenv < Base
      attr_reader :config, :vulenv_config

      def initialize(args)
        super(env_dir: args[:env_dir])
        @config = args[:config]
        @vulenv_config = args[:vulenv_config]
        @error = { flag: false, cause: nil }
      end

      private

      def create_msg
        'Create vulnerability environment'
      end

      def destroy_msg
        "Destroy test_dir(#{env_dir})"
      end

      def prepare_vagrant
        prepare_vagrantfile =
          if vulenv_config['construction']['os']['name'] == 'windows'
            Vagrant::Vagrantfile::Vulenv::Windows.new(
              os_name: vulenv_config['construction']['os']['name'],
              os_version: vulenv_config['construction']['os']['version'],
              env_dir: env_dir
            )
          else
            Vagrant::Vagrantfile::Vulenv::Linux.new(
              os_name: vulenv_config['construction']['os']['name'],
              os_version: vulenv_config['construction']['os']['version'],
              env_dir: env_dir
            )
          end
        prepare_vagrantfile.create

        @vagrant = Vagrant::Command.new
      end

      def prepare_ansible
        Ansible::Vulenv.new(
          cve: vulenv_config['cve'],
          os_name: vulenv_config['construction']['os']['name'],
          db_path: config['vultest_db_path'],
          attack_vector: vulenv_config['attack_vector'],
          env_config: vulenv_config['construction'],
          env_dir: env_dir
        ).create
      end

      def start_vm?
        Dir.chdir(env_dir) do
          { start_up: true, reload: vulenv_config.key?('reload'), hard_setup: vulenv_config['construction'].key?('hard_setup') }.each do |key, value|
            next unless value

            @error[:flag] = !(
              case key
              when :start_up then vagrant.start_up?
              when :reload then vagrant.reload?
              when :hard_setup then vagrant.hard_setup?(vulenv_config['construction']['hard_setup']['msg'])
              end
            )

            next unless error[:flag]

            @error[:cause] = vagrant.stdout
            return false
          end
        end

        manual_setup if vulenv_config['construction'].key?('prepare')

        true
      end

      def manual_setup
        VultestUI.warring('Following execute command')
        puts("  [1] cd #{env_dir}")
        puts('  [2] vagrant ssh')
        vulenv_config['construction']['prepare']['msg'].each.with_index(3) { |msg, i| puts "  [#{i}] #{msg}" }
      end
    end
  end
end
