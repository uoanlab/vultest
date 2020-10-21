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
require 'lib/attack/method/metasploit/core'
require 'lib/attack/create'
require 'lib/print'

module Attack
  class Core
    attr_reader :env_dir, :test_case, :host, :attack_method, :vagrant

    def initialize(args)
      @host = args[:host]
      @user = args[:user]
      @passwd = args[:passwd]
      @env_dir = args[:env_dir]
      @test_case = args[:test_case]
    end

    def create
      create = Create.new(env_dir: env_dir)
      create.exec

      @vagrant = create.vagrant
      vagrant.startup?
    end

    def exec
      @attack_method =
        if test_case.attack_config.key?('metasploit')
          Method::Metasploit::Core.new(host: host, exploits: test_case.attack_config['metasploit'])
        elsif test_case.attack_config.key?('http')
          Method::HTTP.new(exploits: test_case.attack_config['http'])
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
