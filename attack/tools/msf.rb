=begin
Copyright [2019] [Kohei Akasaka]

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Copyright © 2008 Jamis Buck
Relased under the MIT license
https://github.com/net-ssh/net-ssh/blob/master/LICENSE.txt

Copyright (c) Marcin Kulik
Relased under the MIT license
https://github.com/sickill/rainbow/blob/master/LICENSE

Copyright (c) 2016 Piotr Murach
Relased under the MIT license
https://github.com/piotrmurach/tty-command/blob/master/LICENSE.txt

Copyright (c) 2015 Piotr Murach
Relased under the MIT license
https://github.com/piotrmurach/tty-prompt/blob/master/LICENSE.txt

Copyright (c) 2014 Piotr Murach
Relased under the MIT license
https://github.com/piotrmurach/tty-spinner/blob/master/LICENSE.txt

Copyright (c) 2015 Piotr Murach
Relased under the MIT license
https://github.com/piotrmurach/tty-table/blob/master/LICENSE.txt

Copyright (c) 2014 Piotr Murach
Relased under the MIT license
https://github.com/piotrmurach/pastel/blob/master/LICENSE.txt

Copyright (c) 2017 Piotr Murach
Relased under the MIT license
https://github.com/piotrmurach/tty-font/blob/master/LICENSE.txtj

This software includes the work that is distributed in the Apache License 2.0

Reference
https://metasploit.help.rapid7.com/docs/standard-api-methods-reference
https://www.mbsd.jp/blog/20180228.html
=end

require_relative '../../utility'

# Connecting Metasploit API
class MetasploitAPI

  def initialize(rhost)
    # Connection of infomation for Metasploit
    @rhost = rhost
    @port = 55553
    @uri = '/api/'

    # Connecting Metasploit
    @client = Net::HTTP.new(@rhost, @port)

    # User of Metasploit API
    @user = 'msf'
    @password = 'metasploit'
  end

  def msf_api(params)
    req = Net::HTTP::Post.new(@uri)
    req['Content-type'] = 'binary/message-pack'
    req.body = params.to_msgpack
    res_message_pack = @client.request(req)

    return MessagePack.unpack(res_message_pack.body)
  end

  # Login Metasploit by auth.login API
  def auth_login
    params = ['auth.login', @user, @password]
    res = self.msf_api(params)
    @token = res['token']
  end

  # Create MSFconsole by console.create
  def console_create
    params = ['console.create', @token]
    res = self.msf_api(params)
    @console_id = res['id']
  end

  # Execute a command by console.write API
  # The end of the command is \n
  def console_write(command)
    params = ['console.write', @token, @console_id, command]
    res = self.msf_api(params)
  end

  # Get the execution result on MSFconsole by console.read API
  def console_read
    params = ['console.read', @token, @console_id]
    return res = self.msf_api(params)
  end

  # Execute exploit by Metasploit API
  def module_execute (module_type, module_name, options)
    params = ['module.execute', @token, module_type, module_name, options]
    return res = self.msf_api(params)
  end

  # Check result of exploit by session list
  def module_session_list
    params = ['session.list', @token]
    return res = self.msf_api(params)
  end

  def shell_write(session_id, command)
    params = ['session.shell_write', @token, session_id, "#{command}\n"]
    return self.msf_api(params)
  end

  def shell_read(session_id)
    params = ['session.shell_read', @token, session_id, 'ReadPointer']
    return self.msf_api(params)
  end

  def meterpreter_write (session_id, command)
    params = ['session.meterpreter_run_single', @token, session_id, command]
    return self.msf_api(params)
  end

  def meterpreter_read(session_id)
    params = ['session.meterpreter_read', @token, session_id]
    return self.msf_api(params)
  end

end
