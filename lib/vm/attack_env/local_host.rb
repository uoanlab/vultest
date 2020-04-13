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

require './lib/environment/attack_env'

module VM
  module AttackEnv
    class LocalHost
      attr_reader :attack_config, :operating_environment

      def initialize(args)
        @attack_config = args[:attack_config]
        @operating_environment = Environment::AttackEnv.new(
          host: args[:host],
          user: args[:user],
          password: args[:password],
          attack_config: args[:attack_config]
        )
      end
    end
  end
end
