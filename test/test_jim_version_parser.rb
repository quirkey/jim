require 'helper'

class TestJimVersionParser < Test::Unit::TestCase

  context "Jim::VersionParser" do

    context ".parse_filename" do
      should "parse filenames'" do
        [
          ["sammy-0.1.0", ["sammy", "0.1.0"]],
          ["sammy_0.1.0", ["sammy", "0.1.0"]],
          ["/test/fixtures/sammy-0.1.0", ["sammy", "0.1.0"]],
          ["sammy-1", ["sammy", "1"]],
          ["sammy_1", ["sammy", "1"]],
          ["sammy.1.0", ["sammy", "1.0"]],
          ["sammy.1.0.1", ["sammy", "1.0.1"]],
          ["sammy.1.0.1.min", ["sammy", "1.0.1.min"]],
          ["sammy-1.0.1.min", ["sammy", "1.0.1.min"]],
          ["sammy.plugin-1.0.1.min", ["sammy.plugin", "1.0.1.min"]],
          ["sammy.plugin.1.0.1", ["sammy.plugin", "1.0.1"]],
          ["sammy.plugin_1.0.1", ["sammy.plugin", "1.0.1"]],
          ["sammy.plugin.1.0.1pre", ["sammy.plugin", "1.0.1pre"]],
          ["sammy.plugin-1.0.1beta", ["sammy.plugin", "1.0.1beta"]],
          ["sammy.plugin.1.0.1.pre", ["sammy.plugin", "1.0.1.pre"]],
          ["sammy.plugin-1.0.1.beta", ["sammy.plugin", "1.0.1.beta"]],
          ["sammy 1.0.1", ["sammy", "1.0.1"]],
          ["sammy.plugin.1.0.1.js", ["sammy.plugin", "1.0.1"]],
          ["sammy.plugin.1.0.1.zip", ["sammy.plugin", "1.0.1"]],
          ["sammy.plugin.1.0.1", ["sammy.plugin", "1.0.1"]],
          ["sammy.nested_params-0.5.0.js", ["sammy.nested_params", "0.5.0"]],
          # ["sammy.plugin-a9asb02", ["sammy.plugin", "a9asb02"]],
          ["sammy-9asb02", ["sammy", "9asb02"]],
          ["noversion.js", ["noversion", "0"]]
        ].each do |name, result|
          assert_equal result, Jim::VersionParser.parse_filename(name), "Should parse #{name} to #{result.inspect}"
        end
      end

    end
    
    context ".parse_package_json" do
      
      should "parse version and name from file" do
        assert_equal ["mustache", "0.2.2"], Jim::VersionParser.parse_package_json(fixture('mustache.js/package.json'))
      end
      
    end

  end
end