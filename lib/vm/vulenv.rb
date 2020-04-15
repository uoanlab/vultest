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
require './lib/environment/vulenv/ubuntu'
require './lib/environment/vulenv/centos'
require './lib/environment/vulenv/windows'
require './lib/vm/control/vulenv'

module VM
  class Vulenv < Base
    attr_reader :cve, :config, :vulenv_config

    def initialize(args)
      super(env_dir: args[:env_dir])

      @cve = args[:cve]
      @config = args[:config]
      @vulenv_config = args[:vulenv_config]
      @error.merge!({ cause: nil })

      @operating_environment = prepare_operating_envrionment
      @control = prepare_control
    end

    private

    def prepare_control
      Control::Vulenv.new(
        config: config,
        vulenv_config: vulenv_config,
        env_dir: env_dir
      )
    end

    def prepare_operating_envrionment
      case vulenv_config['construction']['os']['name']
      when 'ubuntu' then Environment::Vulenv::Ubuntu.new(vulenv_config: vulenv_config)
      when 'centos' then Environment::Vulenv::CentOS.new(vulenv_config: vulenv_config)
      when 'windows' then Environment::Vulenv::Windows.new(vulenv_config: vulenv_config)
      end
    end
  end
end
