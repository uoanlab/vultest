require 'net/http'
require 'msgpack'
require 'uri'

# Metasploit APIの接続
class MetasploitAPI

  def initialize(rhost)
    # Metasploitの接続情報
    @rhost = rhost
    @port = 55553
    @uri = '/api/'

    # Metasploitに接続
    @client = Net::HTTP.new(@rhost, @port)

    # Metasploit APIのユーザ
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

  # auth.login APIでMetasploitにログイン
  def auth_login
    params = ['auth.login', @user, @password]
    res = self.msf_api(params)
    @token = res['token']
  end

  # console.create APIでMSFconsoleを作成
  def console_create
    params = ['console.create', @token]
    res = self.msf_api(params)
    @console_id = res['id']
  end

  # console.write APIで任意のコマンドを実行
  # コマンド末尾に改行が必要
  def console_write(command)
    params = ['console.write', @token, @console_id, command]
    res = self.msf_api(params)
  end

  # console.read APIでMSFconsole上に出力されたコマンドの実行結果を取得
  def console_read
    params = ['console.read', @token, @console_id]
    return res = self.msf_api(params)
  end

  # Metasploit APIで攻撃を開始
  def module_execute (module_type, module_name, options)
    params = ['module.execute', @token, module_type, module_name, options]
    return res = self.msf_api(params)
  end

  # session listから攻撃の成功を確認
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
