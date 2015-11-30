require 'reapack/index'
require 'minitest/autorun'

TestMetadata = Class.new MiniTest::Test

task :default do
  Dir.glob('**/*.{lua,eel}').each {|file|
    mangled_file = file.downcase
    mangled_file.gsub! /[^\w]/, '_'

    TestMetadata.send(:define_method, "test_#{mangled_file}") do
      errors = ReaPack::Index.validate_file file
      assert_nil errors
    end
  }
end
