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

  it 'checks for rate limit when updating tweets' do
    RestClient.stubs(:get).returns(stub(code: 420))
    JullunchDaemon.expects(:notify).with('Tweets', 'Rate limited').once
    JullunchDaemon.update_tweets
  end

  it 'retrieves the url for Twitter search' do
    test_query = '?q=TEST'

    JullunchDaemon.stubs(:tweets_query).returns(test_query)
    JullunchDaemon.search_twitter_url.must_equal @base_twitter_url + test_query
  end

  it 'changes the url for Twitter search after a sucessful response' do
    refresh_url = '?since_id=123&q=%23athegajul'
    results = [
      {
        from_user: 'athega',
        from_user_id: 16748304,
        from_user_name: "Athega",
        id: 142626039942754300,
        iso_language_code: "sv",
        profile_image_url: "http://a1.twimg.com/profile_images/61956417/athega_e_normal.png",
        source: "&lt;a href=&quot;http://twitter.com/#!/download/iphone&quot; rel=&quot;nofollow&quot;&gt;Twitter for iPhone&lt;/a&gt;",
        text: "Snart dags för årets Jullunch på Athega. #athegajul",
      }
    ]

    body = to_json({ refresh_url: refresh_url, results: results })

    RestClient.stubs(:get).returns(stub(code: 200, to_str: body))

    JullunchDaemon.expects(:notify).once
    JullunchDaemon.search_twitter_url.must_equal @initial_twitter_url
    JullunchDaemon.update_tweets
    JullunchDaemon.search_twitter_url.must_equal @base_twitter_url + refresh_url
  end

  it 'updates images'
end
