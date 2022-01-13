# frozen_string_literal: true

require "project_types/script/test_helper"

describe Script::Layers::Infrastructure::Languages::OtherProjectCreator do
  include TestHelpers::FakeFS

  let(:context) { TestHelpers::FakeContext.new }
  let(:fake_capture2e_response) { [nil, OpenStruct.new(success?: true)] }

  let(:type) { "payment-methods" }
  let(:language) { "other" }
  let(:domain) { "fake-domain" }
  let(:project_name) { "myscript" }
  let(:sparse_checkout_repo) { "fake-repo" }
  let(:sparse_checkout_branch) { "fake-branch" }
  let(:sparse_checkout_set_path) { "#{domain}/#{language}/#{type}/default" }

  let(:project_creator) do
    Script::Layers::Infrastructure::Languages::OtherProjectCreator
      .new(
        ctx: context,
        type: type,
        project_name: project_name,
        path_to_project: project_name,
        sparse_checkout_repo: sparse_checkout_repo,
        sparse_checkout_branch: sparse_checkout_branch,
        sparse_checkout_set_path: sparse_checkout_set_path,
      )
  end

  describe ".setup_dependencies" do
    subject { project_creator.setup_dependencies }

    it "should setup basic script project files" do
      Script::Layers::Infrastructure::Languages::ProjectCreator.any_instance
        .expects(:setup_dependencies)
        .with
        .once

      subject
    end
  end
end
