require 'reapack/index'

task :default do
  require 'minitest/autorun'

  TestMetadata = Class.new MiniTest::Test

  Dir.glob('**/*.{lua,eel}').each {|file|
    mangled_file = file.downcase
    mangled_file.gsub! /[^\w]/, '_'

    TestMetadata.send(:define_method, "test_#{mangled_file}") do
      errors = ReaPack::Index.validate_file file
      assert_nil errors
    end
  }
end

task :index do
  indexer = ReaPack::Index::Indexer.new Dir.pwd
  indexer.run
end
