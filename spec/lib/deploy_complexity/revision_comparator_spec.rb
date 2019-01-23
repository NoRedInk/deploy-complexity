# frozen_string_literal: true

require 'rspec'
require 'deploy_complexity/changed_dependencies'
require 'deploy_complexity/revision_comparator'

class FakeParser < DeployComplexity::ChangedDependencies
  def changes
    ["Added a_cool_dependency 4.2"]
  end
end

describe DeployComplexity::RevisionComparator do
  subject(:comparator) do
    DeployComplexity::RevisionComparator.new(
      FakeParser,
      ["file.txt"],
      "aaa",
      "bbb"
    )
  end

  context "when there are changes" do
    before do
      # Don't actually read from git in tests
      allow(comparator).to receive(:source).and_return("")
    end

    it "should output an array of changes" do
      expect(comparator.output).to eq(["Added a_cool_dependency 4.2"])
    end
  end

  context "when there is an error" do
    before do
      allow(comparator).to receive(:source).and_raise(StandardError.new("bad bad"))
    end

    it "still kindly outputs an array" do
      output = comparator.output
      expect(output).to be_an_instance_of(Array)
      expect(output.first).to eq("bad bad")
    end
  end
end
