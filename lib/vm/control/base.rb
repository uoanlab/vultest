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

require 'bundler/setup'
require 'fileutils'

require 'lib/print'

module VM
  module Control
    class Base
      attr_reader :env_dir, :vagrant, :error

      def initialize(args)
        @env_dir = args[:env_dir]
        @error = { flag: false, cause: nil }
      end

      def create?
        Print.execute(create_msg)

        FileUtils.mkdir_p(env_dir)
        prepare_vagrant
        prepare_ansible

        start_vm?
      end

      def destroy?
        Dir.chdir(env_dir) { return false unless vagrant.destroy! }

        Print.spinner_begin(destroy_msg)
        FileUtils.rm_rf(env_dir)
        Print.spinner_end('success')

        true
      end

      private

      def create_msg
        raise NotImplementedError
      end

      def destroy_msg
        raise NotImplementedError
      end

      def prepare_vagrant
        raise NotImplementedError
      end

      def prepare_ansible
        raise NotImplementedError
      end

      def start_vm?
        raise NotImplementedError
      end
    end
  end
end
