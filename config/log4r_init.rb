require 'log4r'
require 'log4r/yamlconfigurator'
require 'log4r/outputter/fileoutputter'
require 'log4r/outputter/datefileoutputter'
 
# log4r.yml configuration is expected to be in the same directory as this file. 
log4r_config = YAML.load(ERB.new(File.read(File.expand_path(File.dirname(__FILE__) + "/log4r.yml"))).result)
Log4r::YamlConfigurator.decode_yaml(log4r_config['log4r_config'])

SampleApp::Application.config.logger = Log4r::Logger[Rails.env]

