# frozen_string_literal: true

require 'spec_helper'
require 'deploy_complexity/changed_elm_packages'

describe DeployComplexity::ChangedElmPackages do
  let(:old) do
    <<-TXT.gsub(/^\s+/, "")
      {
          "type": "application",
          "source-directories": [],
          "elm-version": "0.19.0",
          "dependencies": {
              "direct": {
                  "elm/core": "1.0.2"
              },
              "indirect": {
                  "elm/json": "1.1.2"
              }
          },
          "test-dependencies": {
              "direct": {},
              "indirect": {}
          }
      }
    TXT
  end

  subject(:changed_elm_packages) do
    DeployComplexity::ChangedElmPackages.new(
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
    context "with no changed packages" do
      let(:new) { old }
      it "returns an empty array" do
        expect(changed_elm_packages.changes).to eq([])
      end
    end

    context "with changed packages" do
      let(:new) do
        <<-TXT.gsub(/^\s+/, "")
          {
              "type": "application",
              "source-directories": [],
              "elm-version": "0.19.0",
              "dependencies": {
                  "direct": {},
                  "indirect": {
                      "elm/json": "1.2.2",
                      "elm/time": "1.0.0"
                  }
              },
              "test-dependencies": {
                  "direct": {
                      "elm-explorations/test": "1.2.0"
                  },
                  "indirect": {}
              }
          }
        TXT
      end

      it "formats the changes" do
        expect(changed_elm_packages.changes).to(
          include(dep("elm/time", current: "1.0.0"),
                  dep("elm-explorations/test", current: "1.2.0"),
                  dep("elm/core", previous: "1.0.2", current: nil),
                  dep("elm/json", previous: "1.1.2", current: "1.2.2"))
        )
      end
    end
  end
end
