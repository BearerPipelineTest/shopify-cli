require 'json'
require 'net/http'

module ShopifyCli
  class TipOfTheDay

    WEEK_IN_SECONDS =  7 * 24 * 60 * 60
    DAY_IN_SECONDS = 24 * 60 * 60
    TIPS_URL = "https://gist.githubusercontent.com/andyw8/c772d254b381789f9526c7b823755274/raw/4b227372049d6a6e5bb7fa005f261c4570c53229/tips.json"

    def initialize(path = nil)
      if path
        @path = path
      else
        @path = File.expand_path(ShopifyCli::ROOT + '/lib/tips.json')
      end
    end

    attr_reader :path

    def self.call(*args)
      new(*args).call
    end

    def call
      if ShopifyCli::Config.get_section('tipoftheday') == {}
        ShopifyCli::Config.set('tipoftheday', 'enabled', true)
      end
      return nil unless ShopifyCli::Config.get_bool('tipoftheday', 'enabled')
      tip = next_tip
      return if tip.nil?
      log_tips(tip)
      tip["text"]
    end

    def next_tip
      tips = fetch_tip
      log = ShopifyCli::Config.get_section("tiplog")

      return unless has_it_been_a_day_since_last_tip?(log)
      tips.each do |tip|
        id = tip["id"]
        unless log.keys.include?(id)
          return tip
        end
      end
      return nil
    end

    def log_tips(tip)
      ShopifyCli::Config.set('tiplog', tip["id"], Time.now.to_i)
    end

    def has_it_been_a_day_since_last_tip?(log)
      most_recent_tip = log.values.last
      return true unless most_recent_tip
      now = Time.now.to_i
      now - most_recent_tip.to_i > DAY_IN_SECONDS
    end

    def fetch_tip
      last_read_time = ShopifyCli::Config.get('tipoftheday', 'lastfetched')
      if !last_read_time || (Time.now.to_i - last_read_time.to_i > WEEK_IN_SECONDS)
        remote_uri = URI(TIPS_URL)
        file = Net::HTTP.get(remote_uri)
        File.write(ShopifyCli.tips_file, file)
        ShopifyCli::Config.set('tipoftheday', 'lastfetched', Time.now.to_i)
      else
        file = File.read(ShopifyCli.tips_file)
      end
      JSON.parse(file)["tips"]
    end
  end
end
