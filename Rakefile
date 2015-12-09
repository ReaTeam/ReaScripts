Signal.trap('INT') { abort }

require 'reapack/index'
require 'awesome_print'

task :default => :test

task :test do
  require 'minitest/autorun'

  module MiniTest
    module Assertions
      def mu_pp(obj)
        obj.awesome_inspect :index => false
      end
    end
  end

  class TestMetadata < MiniTest::Test
    def self.test_order
      :alpha
    end
  end

  Dir.glob('**/*.{lua,eel}').each {|file|
    mangled_file = file.downcase
    mangled_file.gsub! /[^\w]+/, '_'

    TestMetadata.send :define_method, "test_#{mangled_file}" do
      errors = ReaPack::Index.validate_file file
      assert_nil errors
    end
  }
end

task :index do
  ARGV.delete_at 1 if ARGV[1] == '--'

  indexer = ReaPack::Index::Indexer.new Dir.pwd
  indexer.run
end
