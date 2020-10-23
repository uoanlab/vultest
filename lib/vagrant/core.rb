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

module Vagrant
  class Core
    attr_reader :error_msg

    def initialize(args)
      @env_dir = args[:env_dir]
      @host = args[:host]
      @os_name = args[:os_name]
      @os_version = args[:os_version]
      @vagrant_img_box = args.fetch(:vagrant_img_box, nil)

      @error_msg = nil
    end

    def create
      CreateVagrantfile.new(
        host: @host,
        os_name: @os_name,
        os_version: @os_version,
        env_dir: @env_dir,
        vagrant_img_box: @vagrant_img_box
      ).exec
    end

    def startup?
      Dir.chdir(@env_dir) do
        Print.spinner_begin('Startup')
        stdout, _stderr, status = Open3.capture3('vagrant up')
        if status.exitstatus.zero?
          Print.spinner_end('success')
          return true
        end

        Print.spinner_end('error')
        @error_msg = stdout
        false
      end
    end

    def reload?
      Dir.chdir(@env_dir) do
        Print.spinner_begin('Reload')
        stdout, _stderr, status = Open3.capture3('vagrant reload')
        if status.exitstatus.zero?
          Print.spinner_end('success')
          return true
        end

        Print.spinner_end('error')
        @error_msg = stdout
        false
      end
    end

    def halt
      Dir.chdir(@env_dir) { Open3.capture3('vagrant halt') }
    end

    def destroy?
      Dir.chdir(@env_dir) do
        Print.spinner_begin('Destroy the environment')
        _stdout, _stderr, status = Open3.capture3('vagrant destroy -f')
        unless status.exitstatus.zero?
          Print.spinner_end('error')
          return false
        end
        Print.spinner_end('success')
        true
      end
    end
  end
end
