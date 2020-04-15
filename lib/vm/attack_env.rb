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
require './lib/vm/control/attack_env'

module VM
  class AttackEnv < Base
    attr_reader :host, :attack_config

    def initialize(args)
      super(env_dir: args.fetch(:env_dir, nil))

      @host = args[:host]
      @attack_config = args[:attack_config]
      @error.merge!({ cause: nil })

      @operating_environment = prepare_operating_envrionment(args[:user], args[:password])
      @control = prepare_control(args.fetch(:create_flag, true))
    end

    private

    def prepare_control(create_flag = true)
      return nil unless create_flag

      Control::AttackEnv.new(
        host: host,
        attack_config: attack_config,
        env_dir: env_dir
      )
    end

    def prepare_operating_envrionment(user, password)
      Environment::AttackEnv.new(
        host: host,
        user: user,
        password: password,
        attack_config: attack_config
      )
    end
  end
end
