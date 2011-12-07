require_relative "jullunch_daemon/version"

module JullunchDaemon
  extend self

  def notify(title, text)
    puts "=> #{title}: #{text}"
  end

  def setup
    @foo = 'bar'
  end

  def run
    notify('FOO', @foo)
  end
end
