require 'yaml' unless defined?(YAML)
require "yajl"
require "twitter"

require_relative "jullunch_daemon/version"

module JullunchDaemon
  extend self

  CONFIG = File.expand_path("~/.jullunch_daemon/config.yaml")

  DEFAULT_CONFIG = {
    tweets: {
      query: '#athegajul',
      json_file: '~/Desktop/tweets.json',
      consumer_key: 'foo',
      consumer_secret: 'bar'
    },
    images: {
      source_path:          '~/Desktop/images',
      json_file:            '~/Desktop/images.json',
      all_images_json_file: '~/Desktop/all_images.json',
      glob:                 '/hatified*',
      base_url:             'http://assets.athega.se/jullunch/tomtelizer/'
    }
  }

  attr_reader :tweets_query

  def setup
    @config               = load_config
    @tweets_query         = @config[:tweets][:query]

    @tweets_json_file     = File.expand_path(@config[:tweets][:json_file])
    @images_source_path   = File.expand_path(@config[:images][:source_path])
    @images_json_file     = File.expand_path(@config[:images][:json_file])
    @all_images_json_file = File.expand_path(@config[:images][:all_images_json_file])
    @images_glob_path     = "#{@images_source_path}#{@config[:images][:glob]}"

    @twitter_client = Twitter::REST::Client.new({
      consumer_key:    @config[:tweets][:consumer_key],
      consumer_secret: @config[:tweets][:consumer_secret]
    })
  end

  def load_config
    unless File.exist?(CONFIG)
      Dir.mkdir File.dirname(CONFIG) unless File.exist? File.dirname(CONFIG)
      File.open(CONFIG, "w") { |f| f.write DEFAULT_CONFIG.to_yaml }
    end

    YAML.load_file(CONFIG)
  end

  def update_tweets
    new_tweets = @twitter_client.search(tweets_query).map do |t|
      {
        created_at:         t.created_at,
        from_user:          t.user.user_name,
        url:                t.user.url,
        status_url:         t.url,
        from_user_name:     t.user.name,
        id:                 t.id,
        iso_language_code:  t.lang,
        profile_image_url:  t.user.profile_image_url
      }
    end

    if new_tweets.count > 0
      tweets_json = to_json((new_tweets + cached_tweets)[0, 15])

      File.open(@tweets_json_file, "w") { |f| f.write tweets_json }
      notify('Updated tweets', tweets_query)
    end

    notify('update tweets')
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

  def update_all_images
    File.open(@all_images_json_file, "w") { |f| f.write to_json(latest_images(9999)) }
  end

  def latest_images(count = 20)
    base_url = @config[:images][:base_url]

    latest_files(@images_glob_path, count).map { |path|
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

  def json(str)
    Yajl::Parser.parse(str)
  end

  def to_json(obj)
    Yajl::Encoder.encode(obj)
  end
end
