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
require 'lib/attack/method/http'
require 'lib/attack/method/metasploit'
require 'lib/attack/create'
require 'lib/print'

module Attack
  class Core
    attr_reader :env_dir, :attack_config, :attack_method, :vagrant

    def initialize(args)
      @host = args[:host]
      @user = args[:user]
      @passwd = args[:passwd]
      @env_dir = args[:env_dir]
      @attack_config = args[:attack_config]
    end

    def create
      create = Create.new(env_dir: env_dir)
      create.exec

      @vagrant = create.vagrant
      vagrant.startup?
    end

    def exec
      @attack_method =
        if attack_config.key?('metasploit')
          Method::Metasploit.new(host: @host, exploits: attack_config['metasploit'])
        elsif attack_config.key?('http')
          Method::HTTP.new(exploits: attack_config['http'])
        end

      attack_method.exec
    end

    def exec_error?
      return false if attack_method.error.nil?

      true
    end

    def destroy!
      return if vagrant.nil?

      Print.execute("Destroy attack_dir(#{env_dir})")
      Dir.chdir(env_dir) do
        return unless vagrant.destroy?
      end

      FileUtils.rm_rf(env_dir)
      @vagrant = nil
    end
  end
end
