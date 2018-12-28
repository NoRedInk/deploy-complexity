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

  subject(:changed_elm_packages) do
    ChangedElmPackages.new(
      old: old,
      new: new
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
        expect(changed_elm_packages.changes).to eq(
          [
            "Added elm/time: 1.0.0",
            "Added elm-explorations/test: 1.2.0",
            "Removed elm/core: 1.0.2",
            "Updated elm/json: 1.1.2 -> 1.2.2"
          ]
        )
      end
    end
  end
end
