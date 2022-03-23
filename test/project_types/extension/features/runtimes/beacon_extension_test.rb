# frozen_string_literal: true
require "test_helper"
require "project_types/extension/extension_test_helpers"
module Extension
  module Features
    module Runtimes
      class BeaconExtensionTest < MiniTest::Test
        include ExtensionTestHelpers::TempProjectSetup

        private

        def runtime
          @runtime ||= Runtimes::Admin.new
        end
      end
    end
  end
end
