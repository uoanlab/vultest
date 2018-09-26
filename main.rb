require_relative './prompt'
require_relative './vultest'

prompt = Prompt.new()
loop do
  prompt.print_prompt
  input_list = prompt.get_input_command

  # default prompt
  if input_list[0] == 'test'
    Vultest.start_up(input_list[1])
    prompt.set_prompt(input_list[1])
  elsif input_list[0] == 'exit'
    exit!
  end

  #vultest prompt
  if input_list[0] == 'exploit'
    Vultest.attack
  elsif input_list[0] == 'rhost'
    Vultest.set_rhost(input_list[1])
  elsif input_list[0] == 'back'
    Vultest.exit
    prompt.set_prompt('vultest')
  end

end
