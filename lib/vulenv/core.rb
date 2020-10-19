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
require 'fileutils'

require 'lib/vulenv/structure/ubuntu'
require 'lib/vulenv/structure/centos'
require 'lib/vulenv/structure/windows'
require 'lib/vulenv/create'
require 'lib/vulenv/start'
require 'lib/print'

module Vulenv
  class Core
    attr_reader :env_dir, :test_case, :vagrant, :structure

    def initialize(args)
      @env_dir = args[:vulenv_dir]
      @test_case = args[:test_case]
      @vagrant = nil
    end

    def create?
      return unless @structure.nil?

      create = Create.new(
        env_dir: env_dir,
        vulnerability: test_case.vulnerability,
        env_config: test_case.vulenv_config
      )
      create.exec
      @vagrant = create.vagrant

      flag = Start.exec?(
        env_dir: env_dir,
        env_config: test_case.vulenv_config,
        vagrant: vagrant
      )

      @structure = set_structure
      flag
    end

    def error?
      return false if vagrant.error_msg.nil?

      true
    end

    def destroy!
      return if vagrant.nil?

      Print.execute("Destroy test_dir(#{env_dir})")
      Dir.chdir(env_dir) do
        return unless vagrant.destroy?
      end

      FileUtils.rm_rf(env_dir)
      @vagrant = nil
    end

    private

    def set_structure
      env_info = {
        host: '192.168.177.177',
        user: 'vagrant',
        password: 'vagrant',
        env_config: test_case.vulenv_config
      }

      s =
        case test_case.vulenv_config['os']['name']
        when 'ubuntu' then Structure::Ubuntu.new(env_info)
        when 'centos' then Structure::CentOS.new(env_info)
        when 'windows' then Structure::Windows.new(env_info)
        end

      @structure = {
        os: s.os,
        vul_software: s.vul_software,
        related_software: s.related_software,
        ipadders: s.ipaddrs,
        port_list: s.port_list,
        services: s.services
      }
    end
  end
end
