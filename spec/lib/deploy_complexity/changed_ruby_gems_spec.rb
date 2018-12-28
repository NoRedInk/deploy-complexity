# frozen_string_literal: true

require 'spec_helper'
require 'deploy_complexity/changed_ruby_gems'

describe ChangedRubyGems do
  # Parsing relies on whitespace, so we can't really insert these mock gemfiles
  # inline - Rubocop gets angry
  let(:old) { File.read("spec/lib/deploy_complexity/spec_helpers/old_gemfile_lock.txt") }

  subject(:changed_ruby_gems) do
    ChangedRubyGems.new(
      old: old,
      new: new
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
        # TODO: make sure we test if something has moved from GEM -> GIT
        expect(changed_ruby_gems.changes).to eq(
          [
            "Added deploy-complexity: 0.4.0",
            "Added rake: 10.5.0",
            "Removed pry-doc: 0.13.5",
            "Updated pry: 0.12.2 -> 0.12.3"
          ]
        )
      end
    end
  end
end
