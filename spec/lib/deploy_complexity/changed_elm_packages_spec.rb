# frozen_string_literal: true

require 'spec_helper'
require 'deploy_complexity/changed_elm_packages'

describe ChangedElmPackages do
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

  subject(:changed_elm_packages) do
    ChangedElmPackages.new(
      old: old,
      new: new
    )
  end

  describe "#changes" do
    it "generates a list of changed packages" do
      expect(changed_elm_packages.changes).to eq(
        added: {"elm/time" => "1.0.0", "elm-explorations/test" => "1.2.0"},
        removed: { "elm/core" => "1.0.2" },
        updated: { "elm/json" => { old: "1.1.2", new: "1.2.2"} }
      )
    end
  end
end
