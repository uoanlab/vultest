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

require './lib/report/report'
require './lib/report/section/vulenv'
require './lib/report/section/vulnerability'
require './lib/report/section/error/vulenv'

class ErrorVulenvReport < WriteReport
  attr_reader :cve, :control_vulenv

  def initialize(args)
    super(args[:report_dir])
    @control_vulenv = args[:control_vulenv]

    @cve = control_vulenv.cve
  end

  private

  def report_details
    sections = []
    sections.push("# Vultest Report: Error in Construction of Vulnerable Environment\n\n")
    sections.push(create_vulenv_error_section)
    sections.push(create_vulenv_section)
    sections.push(create_vulnerability_section)

    sections
  end

  def create_vulenv_error_section
    section = Report::Section::Error::Vulenv.new(control_vulenv: control_vulenv)
    section.create
  end

  def create_vulenv_section
    section = Report::Section::Vulenv.new(control_vulenv: control_vulenv)
    section.create
  end

  def create_vulnerability_section
    section = Report::Section::Vulnerability.new(cve: cve)
    section.create
  end
end
