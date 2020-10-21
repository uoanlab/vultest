# Copyright [2020] [University of Aizu]
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Command
  module Set
    class << self
      def exec(args)
        setting = args[:setting]

        type = args[:type]
        value = args[:value]

        if type.nil? || value.nil?
          Print.error('The usage of set command is incorrect')
          return
        end

        type = type.downcase
        Print.execute("#{type} => #{value}")

        if type == 'testdir'
          type = 'test_dir'
          value = Util.create_dir(value)
        elsif type[0..5] == 'attack'
          type = "#{type[0..5]}_#{type[6..]}"
          value = Util.create_dir(value) if type == 'attack_dir'
        end

        setting[type.intern] = value
      end
    end
  end
end
