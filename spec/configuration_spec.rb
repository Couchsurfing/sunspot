require File.join(File.dirname(__FILE__), 'spec_helper')

describe "Configuration" do
  it "should handle the 'path' property when not set" do
    config ||= Sunspot::Rails::Configuration.new
    config.path.should == '/solr'
  end

  it "should handle the 'path' property when set" do
    silence_stderr do
      RAILS_ENV = 'path_test'
      config ||= Sunspot::Rails::Configuration.new
      config.path.should == '/solr/path_test'
      RAILS_ENV = 'test'
    end
  end
end