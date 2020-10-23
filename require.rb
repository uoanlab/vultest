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

require 'bundler/setup'

require 'erb'
require 'fileutils'
require 'msgpack'
require 'net/http'
require 'net/ssh'
require 'open3'
require 'optparse'
require 'pastel'
require 'rainbow'
require 'sqlite3'
require 'tty-font'
require 'tty-spinner'
require 'tty-markdown'
require 'tty-prompt'
require 'tty-table'
require 'uri'
require 'winrm'
require 'yaml'

# lib
Dir['./lib/*.rb'].sort.each { |file| require file }

# lib/ansible
Dir['./lib/ansible/*.rb'].sort.each { |file| require file }
require 'lib/ansible/roles/base'
Dir['./lib/ansible/roles/*.rb'].sort.each { |file| require file }
Dir['./lib/ansible/roles/file/*.rb'].sort.each { |file| require file }
Dir['./lib/ansible/roles/mysql/*.rb'].sort.each { |file| require file }
Dir['./lib/ansible/roles/patch/*.rb'].sort.each { |file| require file }
Dir['./lib/ansible/roles/software/*.rb'].sort.each { |file| require file }
Dir['./lib/ansible/roles/software/gem/*.rb'].sort.each { |file| require file }
Dir['./lib/ansible/roles/software/nodenv/*.rb'].sort.each { |file| require file }
Dir['./lib/ansible/roles/software/npm/*.rb'].sort.each { |file| require file }
Dir['./lib/ansible/roles/software/package/*.rb'].sort.each { |file| require file }
Dir['./lib/ansible/roles/software/rbenv/*.rb'].sort.each { |file| require file }
Dir['./lib/ansible/roles/software/source/*.rb'].sort.each { |file| require file }

# lib/api
Dir['./lib/api/*.rb'].sort.each { |file| require file }

# lib/attack
Dir['./lib/attack/*.rb'].sort.each { |file| require file }
Dir['./lib/attack/method/*.rb'].sort.each { |file| require file }
Dir['./lib/attack/method/metasploit/*.rb'].sort.each { |file| require file }

# lib/command
Dir['./lib/command/*.rb'].sort.each { |file| require file }

# lib/vagrant
Dir['./lib/vagrant/*.rb'].sort.each { |file| require file }

# lib/vulenv
Dir['./lib/vulenv/*.rb'].sort.each { |file| require file }
Dir['./lib/vulenv/data/*.rb'].sort.each { |file| require file }

# lib/report
require 'lib/report/base'
Dir['./lib/report/*.rb'].sort.each { |file| require file }
