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

  # auth.login APIでMetasploitにログイン
  def auth_login_module
    req = Net::HTTP::Post.new(@uri)
    req['Content-type'] = 'binary/message-pack'
    params = ['auth.login', @user, @password]
    req.body = params.to_msgpack
    res_message_pack = @client.request(req)

    res = MessagePack.unpack(res_message_pack.body)
    @token = res['token']
  end

  # console.create APIでMSFconsoleを作成
  def console_create_module
    req = Net::HTTP::Post.new(@uri)
    req['Content-type'] = 'binary/message-pack'
    params = ['console.create', @token]
    req.body = params.to_msgpack
    res_message_pack = @client.request(req)

    res = MessagePack.unpack(res_message_pack.body)
    @console_id = res['id']
  end

  # console.write APIで任意のコマンドを実行
  # コマンド末尾に改行が必要
  def console_write_module(command)
    req = Net::HTTP::Post.new(@uri)
    req['Content-type'] = 'binary/message-pack'
    params = ['console.write', @token, @console_id, command]
    req.body = params.to_msgpack
    res_message_pack = @client.request(req)

    res = MessagePack.unpack(res_message_pack.body)
  end

  # console.read APIでMSFconsole上に出力されたコマンドの実行結果を取得
  def console_read_module
    req = Net::HTTP::Post.new(@uri)
    req['Content-type'] = 'binary/message-pack'
    params = ['console.read', @token, @console_id]
    req.body = params.to_msgpack
    res_message_pack = @client.request(req)

    return MessagePack.unpack(res_message_pack.body)
  end
end

msf_api = MetasploitAPI.new()
msf_api.auth_login_module
msf_api.console_create_module

# Metasploitのメニュー画面
command = "search CVE-2017-16995\n"
msf_api.console_write_module(command)
console_read_res = msf_api.console_read_module

# Metasploitにコマンドを送信
=begin
MetasploitのAPIに、コマンドを送る事は成功しているが、Responseを受け取る場合と受け取らない場合が存在するので、Responseを受け取るまでコマンドを送信し続ける処理を追加した。
=end

loop do
  msf_api.console_write_module(command)
  console_read_res = msf_api.console_read_module

  if !console_read_res['data'].empty?
    break
  end
end

for data in console_read_res['data'].split(/\R/)
  p data
end

