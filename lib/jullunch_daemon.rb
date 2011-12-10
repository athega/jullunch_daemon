require 'yaml' unless defined?(YAML)
require "yajl"
require "rest_client"
require "twitter-text"

require_relative "jullunch_daemon/version"

module JullunchDaemon
  extend self

  CONFIG = File.expand_path("~/.jullunch_daemon/config.yaml")

  attr_reader :tweets_query

  def setup
    unless File.exist?(CONFIG)
      Dir.mkdir File.dirname(CONFIG) unless File.exist? File.dirname(CONFIG)

      default_config = {
        tweets: {
          query: '?q=%23athegajul',
          json_file: '~/Desktop/tweets.json'
        },
        images: {
          source_path: '~/Desktop/images',
          json_file: '~/Desktop/images.json',
          glob:        '/hatified*',
          base_url:    'http://assets.athega.se/jullunch/tomtelizer/'
        }
      }

      File.open(CONFIG, "w") { |f| f.write default_config.to_yaml }
    end

    @config = YAML.load_file(CONFIG)

    @tweets_query       = @config[:tweets][:query]
    @tweets_json_file   = File.expand_path(@config[:tweets][:json_file])
    @images_source_path = File.expand_path(@config[:images][:source_path])
    @images_json_file   = File.expand_path(@config[:images][:json_file])
    @images_glob_path   = "#{@images_source_path}#{@config[:images][:glob]}"
  end

  def update_tweets
    response = RestClient.get(search_twitter_url)

    if response.code == 420
      notify('Tweets', 'Rate limited')
    else
      data = json(response.to_str)

      new_tweets = data['results'].map { |t|
        url         = "https://twitter.com/#{t['from_user']}/"
        status_url  = url + "status/#{t['id']}"
        text        = Twitter::Autolink.auto_link(t['text'])

        {
          from_user:          t['from_user'],
          url:                url,
          status_url:         status_url,
          from_user_name:     t['from_user_name'],
          id:                 t['id'],
          iso_language_code:  t['iso_language_code'],
          profile_image_url:  t['profile_image_url'].
                                gsub('normal.', 'reasonably_small.'),
          text:               Twitter::Autolink.html_escape(text)
        }
      }

      if new_tweets.count > 0
        tweets_json = to_json((new_tweets + cached_tweets)[0, 15])
        File.open(@tweets_json_file, "w") { |f| f.write tweets_json }
        notify('Updated tweets', search_twitter_url)
      end

      @tweets_query = data['refresh_url']
    end
  rescue Exception => e
    notify('Exception', e.message)
  end

  def cached_tweets(count = 15)
    tweets = json(IO.read(@tweets_json_file)) if File.exist?(@tweets_json_file)
    tweets.nil? ? [] : tweets[0, count]
  end

  def update_images
    File.open(@images_json_file, "w") { |f| f.write to_json(latest_images) }
  end

  def latest_images()
    base_url = @config[:images][:base_url]

    latest_files(@images_glob_path).map { |path|
      url = "#{base_url}#{File.basename(path)}?size=#{File.size(path)}"
      { url: url, path: path }
    }
  end

  def latest_files(glob_path, count = 20)
    Dir[glob_path].sort_by{ |f| File.ctime(f) }.reverse[0,count]
  end

  def notify(title, text)
    puts "=> #{title}: #{text}"
  end

  def search_twitter_url
    "http://search.twitter.com/search.json#{tweets_query}"
  end

  def json(str)
    Yajl::Parser.parse(str)
  end

  def to_json(obj)
    Yajl::Encoder.encode(obj)
  end
end
