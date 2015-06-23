jasmine_files = ['base',
                 'dependencies',
                 'config',
                 'server',
                 'selenium_driver',
                 'spec_builder',
                 'command_line_tool']

jasmine_files.each do |file|
  require File.join('jasmine', file)
end

require File.join('jasmine', "railtie") if Jasmine::Dependencies.rails3? || Jasmine::Dependencies.rails4?


