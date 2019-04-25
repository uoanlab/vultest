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
https://github.com/piotrmurach/tty-font/blob/master/LICENSE.txt

This software includes the work that is distributed in the Apache License 2.0
=end

require_relative '../../utility'

module Vagrant

  def create(vulconfig_file, vulenv_dir)
    vulconfig = YAML.load_file(vulconfig_file)
    config = YAML.load_file('./config.yml')

    FileUtils.cp_r("./build/vagrant/#{vulconfig['construction']['os']['name']}/#{vulconfig['construction']['os']['version']}/Vagrantfile", "#{vulenv_dir}/Vagrantfile")
  end

  module_function :create

end
