require 'test_helper'
class ConfigTest < ActiveSupport::TestCase

  context 'startup' do
    should 'raise error when no config files found' do
      error = assert_raises Toast::ConfigError do
        Toast.init 'test/files/nonexisting'
      end
      assert_equal "CONFIG ERROR: No config files found in `test/files/nonexisting`",
                   error.message
      assert_equal [], Toast.expositions
    end
  end

  context 'expose directives' do
    should 'register models [A.1]' do
      Toast.init 'test/files/toast_config_1/*'

      assert_equal 2,  Toast.expositions.length

      assert_equal 'Apple', Toast.expositions.first.model_class.name
      assert_equal 'Banana', Toast.expositions.second.model_class.name
    end

    should 'raise error when model not found [A.2]' do
      error = assert_raises Toast::ConfigError do
        Toast.init 'test/files/string.rb'
      end

      assert_equal "CONFIG ERROR: Directive requires an ActiveRecord::Base descendant.\n"+
                   "              directive: /expose(String)\n"+
                   "              in file  : test/files/string.rb:1",
                   error.message

      error = assert_raises Toast::ConfigError do
        Toast.init 'test/files/cherry.rb'
      end

      assert_equal "CONFIG ERROR: uninitialized constant Cherry\n"+
                   "              directive: /\n"+
                   "              in file  : test/files/cherry.rb", # line number is unknown here
                   error.message
    end

    should 'register media types [A.3]' do
      Toast.init 'test/files/toast_config_1/*'

      a,b = Toast.expositions

      assert_equal 'application/apple+json',    a.media_type
      assert_equal 'application/banana+json',   b.media_type
    end

    should 'register URL path prefixes [A.4]' do

      Toast.init 'test/files/toast_config_1/*'
      a,b = Toast.expositions

      assert_equal [],                a.url_path_prefix
      assert_equal ['test','api-v1'], b.url_path_prefix
    end

    should 'register writable attributes [A.5]' do
      Toast.init 'test/files/toast_config_1/*'
      a,b = Toast.expositions

      assert_equal [:name, :number],          a.writables
      assert_equal [:name, :number, :weight], b.writables
    end

    should 'register readable attributes [A.6]' do

      Toast.init 'test/files/toast_config_1/*'
      a,b  = Toast.expositions

      assert_equal [],           a.readables
      assert_equal [:curvature], b.readables

    end

    should 'register collections [A.7]' do
      Toast.init 'test/files/toast_config_1/*'
      a,b = Toast.expositions

      assert_equal OpenStruct,                           a.collections[:all].class
      assert_equal [:query,:all,:less_than_hundred],     b.collections.keys

    end

    should 'register singles [A.8]' do
      Toast.init 'test/files/toast_config_1/*'
      a,b = Toast.expositions

      assert_equal [:first], a.singles.keys
      assert_equal [:first, :last], b.singles.keys
    end

    should 'register associations [A.9]' do
      Toast.init 'test/files/toast_config_1/*'
      a,b = Toast.expositions

      assert_equal 2,                        a.associations.size
      assert_equal :bananas,                 a.associations[:bananas].assoc_name
      assert_equal 'Apple',                  a.associations[:bananas].base_model_class.name

      assert_equal 1,                         b.associations.size
      assert_equal :apple,                    b.associations[:apple].assoc_name
      assert_equal 'Banana',                  b.associations[:apple].base_model_class.name
    end

    should 'register via_get, via_patch and via_delete directives [A9,A10,A11]' do
      Toast.init 'test/files/via_verb.rb'
      config = Toast.expositions.first

      assert_equal OpenStruct, config.via_get.class
      assert_equal OpenStruct, config.via_patch.class
      assert_equal OpenStruct, config.via_delete.class
      assert_nil        config.via_post
      assert_nil        config.via_link
      assert_nil        config.via_unlink
    end

    should 'raise error when block missing' do

      error = assert_raises Toast::ConfigError do
        Toast.init 'test/files/no-expose-block.rb'
      end

      assert_equal "CONFIG ERROR: Block expected.\n"+
                   "              directive: /expose(Apple)\n"+
                   "              in file  : test/files/no-expose-block.rb:1",
                   error.message

    end

    should 'raise error when readable attributes missing' do

      error = assert_raises Toast::ConfigError do
        Toast.init 'test/files/readables_missing.rb'
      end

      assert_equal "CONFIG ERROR: Exposed attribute getter not found `Banana#non_existent'. Typo?\n"+
                   "              directive: /expose(Banana)/readables(:curvature,:non_existent)\n"+
                   "              in file  : test/files/readables_missing.rb:5",
                   error.message


    end

    should 'raise error when writable attributes missing' do
      error = assert_raises Toast::ConfigError do
        Toast.init 'test/files/writables_missing.rb'
      end

      assert_equal "CONFIG ERROR: Exposed attribute setter not found: `Banana#color='. Typo?\n"+
                   "              directive: /expose(Banana)/writables(:name,:number,:color)\n"+
                   "              in file  : test/files/writables_missing.rb:3",
                   error.message

    end

    should 'raise error on unknown directives' do
      error = assert_raises Toast::ConfigError do
        Toast.init 'test/files/unknown_directive.rb'
      end

      assert_equal "CONFIG ERROR: Unknown directive: `good_morning'\n"+
                   "              directive: /expose(Banana)\n"+
                   "              in file  : test/files/unknown_directive.rb:6",
                   error.message
    end
  end # context "expose directives"

  context 'association directives' do
    should 'register via_get, via_post, via_link and via_unlink configs [B.1]'  do
      Toast.init 'test/files/via_verb.rb'
      config = Toast.expositions.first
      assert_equal OpenStruct, config.associations[:apple].via_get.class
      assert_nil config.associations[:apple].via_post
      assert_equal OpenStruct, config.associations[:apple].via_link.class
      assert_equal OpenStruct, config.associations[:apple].via_unlink.class
      assert_equal OpenStruct, config.associations[:coconuts].via_post.class
    end

    should 'raise error when via_post defined for singular association' do
      error = assert_raises Toast::ConfigError do
        Toast.init 'test/files/invalid_via_post.rb'
      end

      assert_equal "CONFIG ERROR: `via_post' is not allowed for singular associations\n"+
                   "              directive: /expose(Banana)/association(:apple)/via_post\n"+
                   "              in file  : test/files/invalid_via_post.rb:18",
                   error.message
    end

    should 'raise error when association missing' do

      error = assert_raises Toast::ConfigError do
        Toast.init 'test/files/assoc_missing.rb'
      end

      assert_equal "CONFIG ERROR: Association expected\n"+
                   "              directive: /expose(Banana)/association(:cherries)\n"+
                   "              in file  : test/files/assoc_missing.rb:7",
                   error.message

    end

    should 'raise error when block missing' do

      error = assert_raises Toast::ConfigError do
        Toast.init 'test/files/assoc_block_missing.rb'
      end

      assert_equal "CONFIG ERROR: Block expected.\n"+
                   "              directive: /expose(Banana)/association(:apple)\n"+
                   "              in file  : test/files/assoc_block_missing.rb:6",
                   error.message

     end

    should 'raise error on unknown directives' do
      error = assert_raises Toast::ConfigError do
        Toast.init 'test/files/unknown_directive_in_assoc.rb'
      end

      assert_equal "CONFIG ERROR: Unknown directive: `good_morning'\n"+
                   "              directive: /expose(Banana)/association(:apple)\n"+
                   "              in file  : test/files/unknown_directive_in_assoc.rb:7",
                   error.message
    end

    should 'register max window size [B.2]' do
      Toast.init 'test/files/toast_config_1/*.rb'

      a,b = Toast.expositions

      assert_equal 100, a.associations[:bananas].max_window
      assert_equal 30 , a.associations[:eggplants].max_window  # default
      assert_nil b.associations[:apple].max_window  # singular

    end
  end

  context 'via_* directives' do
    should 'register "allow" rules [D.1]' do
      Toast.init 'test/files/assoc_allow.rb'

      config = Toast.expositions.first

      assert_equal 2, config.associations[:apple].via_get.permissions.length
      assert_equal [Proc,Proc], config.associations[:apple].via_get.permissions.map(&:class)
      assert_equal [3,-1], config.associations[:apple].via_get.permissions.map(&:arity)

    end

    should 'raise error on invalid "allow" rules [D.1]' do

      error = assert_raises Toast::ConfigError do
        Toast.init 'test/files/assoc_invalid_allow.rb'
      end

      assert_equal "CONFIG ERROR: Allow rule must list arguments as |*all|, |auth, *rest| or |auth, request_model, uri_params|\n"+
                   "              directive: /expose(Banana)/association(:apple)/via_get/allow\n"+
                   "              in file  : test/files/assoc_invalid_allow.rb:12",
                   error.message

    end

    should 'register "handler" blocks [D.2]' do
      Toast.init 'test/files/assoc_handler.rb'

      config = Toast.expositions.first

      assert_equal Proc, config.associations[:apple].via_get.handler.class
      assert_equal 2, config.associations[:apple].via_get.handler.arity
    end

    should 'raise error on invalid "handler" blocks [D.2]' do

      error = assert_raises Toast::ConfigError do
        Toast.init 'test/files/assoc_invalid_handler.rb'
      end

      assert_equal "CONFIG ERROR: Handler block must take exactly 2 arguments\n"+
                   "              directive: /expose(Banana)/association(:apple)/via_get/handler\n"+
                   "              in file  : test/files/assoc_invalid_handler.rb:17",
                   error.message
    end
  end

  context 'collection directives' do
    should 'register via_get and via_post configs [C.1]'  do
      Toast.init 'test/files/via_verb.rb'
      config = Toast.expositions.first
      assert_equal OpenStruct, config.collections[:all].via_get.class
      assert_equal OpenStruct, config.collections[:all].via_post.class
      assert_equal OpenStruct, config.collections[:query].via_get.class
      assert_nil config.collections[:query].via_post
    end

    should 'register max window size [B.2]' do
      Toast.init 'test/files/toast_config_1/*.rb'

      a,b  = Toast.expositions

      assert_equal 30, a.collections[:all].max_window
      assert_equal 30, b.collections[:all].max_window
      assert_equal 99, b.collections[:query].max_window

    end


    should 'raise error on invalid "handler" blocks [D.2]' do

      error = assert_raises Toast::ConfigError do
        Toast.init 'test/files/collection_invalid_handler.rb'
      end

      assert_equal "CONFIG ERROR: Handler block must take exactly 1 argument\n"+
                   "              directive: /expose(Banana)/collection(:query)/via_get/handler\n"+
                   "              in file  : test/files/collection_invalid_handler.rb:36",
                   error.message
    end
  end

  context 'single directives' do
    should 'register via_get configs [E.1]' do
      Toast.init 'test/files/via_verb.rb'
      config = Toast.expositions.first
      assert_equal OpenStruct, config.singles[:first].via_get.class
    end

    should 'raise error on invalid "handler" blocks [D.2]' do

      error = assert_raises Toast::ConfigError do
        Toast.init 'test/files/single_invalid_handler.rb'
      end

      assert_equal "CONFIG ERROR: Handler block must take exactly 1 argument\n"+
                   "              directive: /expose(Banana)/single(:last)/via_get/handler\n"+
                   "              in file  : test/files/single_invalid_handler.rb:10",
                   error.message
    end
  end

  context 'global settings' do
    should 'be registered' do
      Toast.init 'test/files/toast_config_1/*', 'test/files/settings.rb'

      assert_equal 1090, Toast.settings.max_window
      assert_equal true, Toast.settings.link_unlink_via_post
      assert_equal "Lorem ipsum", Toast.settings.authenticate.call("lorem ipsum")
    end

    should 'use defaults if not found or partially defined' do
      Toast.init 'test/files/toast_config_1/*', 'not-existing.rb'

      assert_equal 42, Toast.settings.max_window
      assert_equal false, Toast.settings.link_unlink_via_post
      assert_equal "lorem ipsum", Toast.settings.authenticate.call("lorem ipsum")
    end

    should 'raise error if invalid setting found' do
      error = assert_raises Toast::ConfigError do
        Toast.init 'test/files/toast_config_1/*', 'test/files/settings-invalid.rb'
      end

      assert_equal "CONFIG ERROR: Unknown directive: `maxx_window'\n"+
                   "              directive: /toast_settings\n"+
                   "              in file  : test/files/settings-invalid.rb:2",
                   error.message

      error = assert_raises Toast::ConfigError do
        Toast.init 'test/files/toast_config_1/*', 'test/files/settings-invalid2.rb'
      end

      assert_equal "CONFIG ERROR: Unknown directive: `toast'\n"+
                   "              directive: /\n"+
                   "              in file  : test/files/settings-invalid2.rb:1",
                   error.message
    end
  end
end
