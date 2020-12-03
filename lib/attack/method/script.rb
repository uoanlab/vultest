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

module Attack
  module Method
    class Script
      attr_reader :result

      def initialize(args)
        exploits = args[:exploits]

        @host = exploits['host']
        @user = exploits['user']
        @passwd = exploits['passwd']
        @path = "#{exploits['dir']}/#{exploits['file']}"
        @cmd = "#{exploits['executable']} #{@path}"
        @content = exploits['content']

        @result = {
          status: 'unknown',
          host: @host,
          user: @user,
          passwd: @passwd,
          executable: exploits['executable'].split('/').last,
          cmd: @cmd,
          content: @content
        }
      end

      def exec
        Net::SSH.start(@host, @user, password: @passwd, verify_host_key: :never) do |ssh|
          ssh.exec!("echo \"#{@content}\" > #{@path}")
          puts ssh.exec!(@cmd)
        end
      rescue StandardError
        @result[:status] = 'error'
      end
    end
  end
end
