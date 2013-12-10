# encoding: UTF-8

require 'minitest/pride'
require 'minitest/spec'
require 'minitest/autorun'
require 'mocha/setup'

require_relative '../lib/jullunch_daemon'

def to_json(obj)
  Yajl::Encoder.encode(obj)
end

describe JullunchDaemon do
  before do
    @base_twitter_url     = 'http://search.twitter.com/search.json'
    @initial_twitter_url  = @base_twitter_url + '?q=%23athegajul'

    JullunchDaemon.stubs(:load_config).returns(JullunchDaemon::DEFAULT_CONFIG)

    JullunchDaemon.setup
  end

  it 'can notify' do
    -> { JullunchDaemon.notify 'foo', 'bar' }.must_output "=> foo: bar\n"
  end
end
