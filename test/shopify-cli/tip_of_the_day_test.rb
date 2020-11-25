# frozen_string_literal: true
require 'test_helper'
require 'shopify-cli/tip_of_the_day'
require 'timecop'

module ShopifyCli
  class TipOfTheDayTest < MiniTest::Test
    include TestHelpers::FakeFS

    def setup
      super
      root = ShopifyCli::ROOT
      FakeFS::FileSystem.clone(root + '/test/fixtures/tips.json')
      Dir.mkdir(root + '/.tmp')
      @tips_path = File.expand_path(ShopifyCli::ROOT + '/test/fixtures/tips.json')

      @remote_request = stub_request(:get, "https://gist.githubusercontent.com/andyw8/c772d254b381789f9526c7b823755274/raw/4b227372049d6a6e5bb7fa005f261c4570c53229/tips.json")
        .to_return(status: 200, body: File.read(@tips_path), headers: {})
    end

    def teardown
      ShopifyCli::Config.clear
      super
    end

    def test_displays_first_tip
      result = TipOfTheDay.call(@tips_path)
      assert_includes result, 'Creating a new store'
    end

    def test_displays_sequential_tip
      TipOfTheDay.call(@tips_path)
      Timecop.travel(36 * 60 * 60) do
        result = TipOfTheDay.call(@tips_path)
        assert_includes result, 'Did you know this CLI is open source'
      end
    end

    def test_displays_nothing_when_all_tips_have_been_seen
      3.times do
        TipOfTheDay.call(@tips_path)
      end

      assert_nil TipOfTheDay.call(@tips_path)
    end

    def test_no_tips_shown_if_disabled_in_config
      ShopifyCli::Config.set('tipoftheday', 'enabled', false)

      assert_nil TipOfTheDay.call(@tips_path)
    end

    def test_tips_shown_if_reenabled_in_config
      ShopifyCli::Config.set('tipoftheday', 'enabled', false)

      assert_nil TipOfTheDay.call(@tips_path)

      ShopifyCli::Config.set('tipoftheday', 'enabled', true)
      result = TipOfTheDay.call(@tips_path)

      assert_includes result, 'Creating a new store'
    end

    def test_only_shows_one_tip_per_day
      TipOfTheDay.call(@tips_path)
      assert_nil TipOfTheDay.call(@tips_path)
    end

    def test_fetches_tips_from_remote
      TipOfTheDay.call

      assert_requested(@remote_request)
    end

    def test_saves_local_copy_of_fetched_tip_data
      TipOfTheDay.call
      assert File.exist?(ShopifyCli.tips_file)
    end

    def test_fetching_tips_updates_config_timestamp
      Timecop.freeze do |time|
        TipOfTheDay.call
        last_read_time = ShopifyCli::Config.get('tipoftheday', 'lastfetched').to_i
        assert_equal last_read_time, time.to_i
      end
    end

    def test_fetch_data_when_week_passes
      TipOfTheDay.call
      Timecop.travel(8 * 24 * 60 * 60) do
        TipOfTheDay.call
        assert_requested(@remote_request, times: 2)
      end
    end

    def test_does_not_fetch_data_within_a_week
      TipOfTheDay.call
      TipOfTheDay.call

      assert_requested(@remote_request, times: 1)
    end

    def test_skip_when_4xx_error
      remove_request_stub(@remote_request)
      stub_request(:get, "https://gist.githubusercontent.com/andyw8/c772d254b381789f9526c7b823755274/raw/4b227372049d6a6e5bb7fa005f261c4570c53229/tips.json")
        .to_return(status: 404, body: "", headers: {})

      assert_nil TipOfTheDay.call
      assert_equal({}, ShopifyCli::Config.get_section('tiplog'))
    end

    def test_skip_when_request_timeout
      remove_request_stub(@remote_request)
      stub_request(:get, "https://gist.githubusercontent.com/andyw8/c772d254b381789f9526c7b823755274/raw/4b227372049d6a6e5bb7fa005f261c4570c53229/tips.json")
        .to_timeout

      assert_nil TipOfTheDay.call
      assert_equal({}, ShopifyCli::Config.get_section('tiplog'))
    end
  end
end