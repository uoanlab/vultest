# Copyright [2019] [University of Aizu]
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
#
# reference: https://www.mbsd.jp/blog/20180228.html

require 'bundler/setup'
require 'msgpack'
require 'net/http'

class Metasploit
  def initialize(rhost)
    @rhost = rhost
    @port = 55_553
    @uri = '/api/'

    @client = Net::HTTP.new(@rhost, @port)

    @user = 'msf'
    @password = 'metasploit'
  end

  def msf_api(params)
    req = Net::HTTP::Post.new(@uri)
    req['Content-type'] = 'binary/message-pack'
    req.body = params.to_msgpack
    res_message_pack = @client.request(req)

    MessagePack.unpack(res_message_pack.body)
  end

  def auth_login
    params = ['auth.login', @user, @password]
    res = msf_api(params)
    @token = res['token']
  end

  def console_create
    params = ['console.create', @token]
    res = msf_api(params)
    @console_id = res['id']
  end

  # The end of the command is \n
  def console_write(command)
    params = ['console.write', @token, @console_id, command]
    msf_api(params)
  end

  def console_read
    params = ['console.read', @token, @console_id]
    msf_api(params)
  end

  def module_execute(args)
    params = ['module.execute', @token, args[:type], args[:name], args[:option]]
    msf_api(params)
  end

  def module_session_list
    params = ['session.list', @token]
    msf_api(params)
  end

  def shell_write(args)
    params = ['session.shell_write', @token, args[:id], "#{args[:cmd]}\n"]
    msf_api(params)
  end

  def shell_read(session_id)
    params = ['session.shell_read', @token, session_id, 'ReadPointer']
    msf_api(params)
  end

  def meterpreter_write(args)
    params = ['session.meterpreter_run_single', @token, args[:id], args[:cmd]]
    msf_api(params)
  end

  def meterpreter_read(session_id)
    params = ['session.meterpreter_read', @token, session_id]
    msf_api(params)
  end

  def session_stop(session_id)
    params = ['session.stop', @token, session_id]
    msf_api(params)
  end

  def job_list
    params = ['job.list', @token]
    msf_api(params)
  end

  def job_info(job_id)
    params = ['job.info', @token, job_id]
    msf_api(params)
  end

  def job_stop(job_id)
    params = ['job.stop', @token, job_id]
    msf_api(params)
  end
end
