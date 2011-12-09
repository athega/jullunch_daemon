require 'yaml' unless defined?(YAML)
require "yajl"
require "rest_client"

require_relative "jullunch_daemon/version"

module JullunchDaemon
  extend self

  CONFIG = File.expand_path("~/.jullunch_daemon/config.yaml")

  attr_reader :twitter_query

  def setup
    unless File.exist?(CONFIG)
      Dir.mkdir File.dirname(CONFIG) unless File.exist? File.dirname(CONFIG)

      default_config = {
        twitter: {
          query: '?q=%23athegajul',
          json_file: '~/Desktop/twitter.json'
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
    @twitter_query = @config[:twitter][:query]

    @images_source_path = File.expand_path(@config[:images][:source_path])
    @images_glob_path   = "#{@images_source_path}#{@config[:images][:glob]}"
    @images_json_file   = File.expand_path(@config[:images][:json_file])
  end

  def run
    update_images
  end

  def update_tweets
    response = RestClient.get(search_twitter_url)

    if response.code == 420
      notify('Tweets', 'Rate limited')
    else
      data = json(response.to_str)

      @twitter_query = data['refresh_url']
      notify('Updated tweets', search_twitter_url)
    end
  end

  def update_images
    images = latest_images

    File.open(@images_json_file, "w") { |f| f.write to_json(images) }

    notify('Updated images', images.count)
  end

  def latest_images
    base_url = @config[:images][:base_url]

    latest_files(@images_glob_path).map { |path|
      { url: "#{base_url}#{File.basename(path)}?#{random}", path: path }
    }
  end

  def latest_files(glob_path, count = 20)
    Dir[glob_path].sort_by{ |f| File.ctime(f) }.reverse[0,count]
  end

  def notify(title, text)
    puts "=> #{title}: #{text}"
  end

  def search_twitter_url
    "http://search.twitter.com/search.json#{twitter_query}"
  end

  def random(size = 10000)
    (rand()*size).to_i
  end

  def json(str)
    Yajl::Parser.parse(str)
  end

  def to_json(obj)
    Yajl::Encoder.encode(obj)
  end
end
