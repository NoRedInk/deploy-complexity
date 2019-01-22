# frozen_string_literal: true

require 'spec_helper'
require 'deploy_complexity/changed_ruby_gems'

describe DeployComplexity::ChangedRubyGems do
  # Parsing relies on whitespace, so we can't really insert these mock gemfiles
  # inline - Rubocop gets angry
  let(:old) { File.read("spec/lib/deploy_complexity/spec_helpers/old_gemfile_lock.txt") }

  subject(:changed_ruby_gems) do
    DeployComplexity::ChangedRubyGems.new(
      file: "file_path",
      old: old,
      new: new
    )
  end

  def dep(package, current: nil, previous: nil, file: "file_path")
    DeployComplexity::Dependency.with(
      package: package, file: file, current: current, previous: previous
    )
  end

  describe "#changes" do
    context "with no changed gems" do
      let(:new) { old }
      it "returns an empty array" do
        expect(changed_ruby_gems.changes).to eq([])
      end
    end

    context "with changed gems" do
      let(:new) { File.read("spec/lib/deploy_complexity/spec_helpers/new_gemfile_lock.txt") }

      it "formats the changes" do
        expect(changed_ruby_gems.changes).to(
          include(
            dep("deploy-complexity", current: "0.4.0"),
            dep("rake", current: "10.5.0"),
            dep("pry-doc", previous: "0.13.5"),
            dep("babadook", previous: "1.0.0", current: "1.0.0 (GIT https://github.com/notrubygems.git bbbb)"),
            dep("pry", previous: "0.12.2", current: "0.12.3")
          )
        )
      end
    end
  end
end
