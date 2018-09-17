require_relative 'lib/global/setting'
require_relative 'lib/command/module'
require_relative 'lib/env/module'
require_relative 'lib/attack/module'

font = TTY::Font.new(:"3d")
pastel = Pastel.new
puts pastel.red(font.write("VULTEST"))

# create database
db = SQLite3::Database.new("./db/vultest.db")
db.results_as_hash = true

loop do
  print 'vultest >'
  command = gets
  command = command.chomp!
  command_line = command.split(" ")

  # test command
  if command_line[0] == 'test' then
    attack_vector_list, vul_env_config_list, attack_config_file_path_list = create_vulenv_dir_module(command_line[1], db)

    header = ['id', 'vulnerability environment path']
    table = TTY::Table.new header, vul_env_config_list

    puts "#{$list_symbol} vulnerability environment list"
    table.render(:ascii).each_line do |line|
      puts line.chomp
    end
    print "\n"

    id_list = []
    vul_env_config_list.each do |id, vul_env_path|
      id_list.push(id.to_s)
    end
    prompt = TTY::Prompt.new
    id = prompt.enum_select("#{$caution_symbol} Select an id for testing vulnerability envrionment?", id_list)

    create_vulenv_module(id)

    if attack_vector_list[id.to_i] == 'local' then
      message = Rainbow('attack vector is local').green
      puts "#{$caution_symbol} #{message}"
      message = Rainbow('following execute command').green
      puts "#{$caution_symbol} #{message}"
      puts '[1] vagrant ssh'
      puts '[2] sudo su - msf'
      puts '[3] cd metasploit-framework'
      puts '[4] ./msfconsole'
      puts '[5] load msgrpc ServerHost=192.168.33.10 ServerPort=55553 User=msf Pass=metasploit '

      host = '192.168.33.10'
    else 
      puts "#{$caution_symbol} input ip address of machine for attack"
      puts "#{$caution_symbol} start up kali linux"
      print "ip address> "
      host = gets
      host = host.chomp!
    end

    loop do
      print "#{command_line[1]}> "
      exploit_command = gets
      exploit_command = exploit_command.chomp!

      if exploit_command == 'exploit' then
        attack_module(host, attack_config_file_path_list[id.to_i])
      elsif exploit_command == 'exit' then
        break
      end
    end

  # exit command
  elsif command_line[0] == 'exit' then
    break
  # command (ls, echo etc)
  else
    cmd = TTY::Command.new
    cmd.run(command)
  end

end
