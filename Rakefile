require 'metaheader'
require 'minitest/autorun'

RULES = {
  :version => /\A(?:[^\d]*\d+[^\d]*){1,4}\z/
}

TestMetadata = Class.new MiniTest::Test

task :default do
  Dir.glob('**/*.{lua,eel}').each {|file|
    mangled_file = file.downcase
    mangled_file.gsub! /[^\w]/, '_'

    TestMetadata.send(:define_method, "test_#{mangled_file}") do
      mh = MetaHeader.from_file file
      assert_nil mh.validate RULES
    end
  }
end
