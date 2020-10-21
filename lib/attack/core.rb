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

module Attack
  class Core
    attr_reader :env_dir, :vagrant

    def initialize(args)
      @host = args[:host]
      @user = args[:user]
      @passwd = args[:passwd]
      @env_dir = args[:env_dir]
      @test_case = args[:test_case]

      @attack = nil
    end

    def create
      create = Create.new(env_dir: env_dir)
      create.exec

      @vagrant = create.vagrant
      vagrant.startup?
    end

    def exec
      @attack =
        if @test_case.attack_config.key?('metasploit')
          Method::Metasploit::Core.new(
            host: @host,
            exploits: @test_case.attack_config['metasploit']
          )
        elsif @test_case.attack_config.key?('http')
          Method::HTTP.new(exploits: @test_case.attack_config['http'])
        end

      @attack.exec
    end

    def result
      @attack.result
    end

    def attack_method
      if @attack.instance_of?(::Attack::Method::Metasploit::Core) then 'metasploit'
      elsif @attack.instance_of?(::Attack::Method::HTTP) then 'http'
      end
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
