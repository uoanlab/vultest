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

module Vagrant
  VAGRANTFILR_TEMPLATE_PATH = './resources/vagrant/Vagrantfile.erb'.freeze

  class CreateVagrantfile
    def initialize(args)
      @host = args[:host]
      @os_name = args[:os_name]
      @os_version = args[:os_version]
      @env_dir = args[:env_dir]
      @vagrant_img_box = args.fetch(:vagrant_img_box, nil)
    end

    def exec
      FileUtils.mkdir_p(@env_dir)

      if !@vagrant_img_box.nil?
        write_vagrantfile(box_name: @vagrant_img_box)
      elsif @os_name == 'windows' || TTY::Prompt.new.yes?('Do you select a vagrant image in local?')
        use_local_vagrant_image
        return unless @os_name == 'windows'

        Dir.chdir(@env_dir) do
          Open3.capture3('wget https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1')
        end

      elsif TTY::Prompt.new.yes?('Do you select a vagrant image in Vagrant Cloud?')
        use_vagrant_cloud_image

      elsif File.exist?("./resources/vagrant/#{@os_name}/#{@os_version}/Vagrantfile")
        FileUtils.cp_r(
          "./resources/vagrant/#{@os_name}/#{@os_version}/Vagrantfile", "#{@env_dir}/Vagrantfile"
        )
      end
    end

    private

    def use_local_vagrant_image
      Print.command('Please, you select a vagrant image below:')
      Print.stdout("  OS name: #{@os_name}")
      Print.stdout("  OS version: #{@os_version}")

      box = SelectVagrantImage.new.exec
      write_vagrantfile(box)
    end

    def use_vagrant_cloud_image
      box = {}
      Print.command('Please, you select a vagrant image below:')
      Print.stdout("  OS name: #{@os_name}")
      Print.stdout("  OS version: #{@os_version}")

      print('Name of Vagrant image: ')
      box[:box_name] = gets.chomp!

      print('Version of Vagrant image: ')
      box[:box_version] = gets.chomp!

      write_vagrantfile(box)
    end

    def write_vagrantfile(box)
      erb = ERB.new(File.read(VAGRANTFILR_TEMPLATE_PATH), trim_mode: 2)

      os_name = @os_name
      box_name = box[:box_name]
      box_version = box.fetch(:box_version, nil)
      host = @host

      File.open("#{@env_dir}/Vagrantfile", 'w') { |f| f.puts(erb.result(binding)) }
    end
  end
end
