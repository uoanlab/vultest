require 'net/http'
require 'msgpack'
require 'uri'

# Metasploit APIの接続
class MetasploitAPI

  def initialize
    # Metasploitの接続情報
    @host = '192.168.33.10'
    @port = 55553
    @uri = '/api/'

    # Metasploitに接続
    @client = Net::HTTP.new(@host, @port)

    # Metasploit APIのユーザ
    @user = 'msf'
    @password = 'metasploit'
  end

  def msf_api_module(params)
    req = Net::HTTP::Post.new(@uri)
    req['Content-type'] = 'binary/message-pack'
    req.body = params.to_msgpack
    res_message_pack = @client.request(req)

    return MessagePack.unpack(res_message_pack.body)
  end

  # auth.login APIでMetasploitにログイン
  def auth_login_module
    params = ['auth.login', @user, @password]
    res = self.msf_api_module(params)
    @token = res['token']
  end

  # console.create APIでMSFconsoleを作成
  def console_create_module
    params = ['console.create', @token]
    res = self.msf_api_module(params)
    @console_id = res['id']
  end

  # console.write APIで任意のコマンドを実行
  # コマンド末尾に改行が必要
  def console_write_module(command)
    params = ['console.write', @token, @console_id, command]
    res = self.msf_api_module(params)
  end

  # console.read APIでMSFconsole上に出力されたコマンドの実行結果を取得
  def console_read_module
    params = ['console.read', @token, @console_id]
    return res = self.msf_api_module(params)
  end


  # Metasploit APIで攻撃を開始
  def module_execute_module (module_type, module_name, options)
    params = ['module.execute', @token, module_type, module_name, options]
    return res = self.msf_api_module(params)
  end

  # session listから攻撃の成功を確認
  def module_session_list
    params = ['session.list', @token]
    return res = self.msf_api_module(params)
  end

end
