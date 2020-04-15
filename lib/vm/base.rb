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

module VM
  class Base
    attr_reader :env_dir, :error, :control, :operating_environment

    def initialize(args)
      @env_dir = args[:env_dir]
      @error = { flag: false }
    end

    def create?
      return false if control.nil?

      if control.create? then true
      else
        @error.merge!(control.error)
        false
      end
    end

    def destroy?
      return false if control.nil?

      control.destroy?
      true
    end

    private

    def prepare_control
      raise NotImplementedError
    end

    def prepare_operating_envrionment
      raise NotImplementedError
    end
  end
end
