# frozen_string_literal: true

require 'spec_helper'
require 'deploy_complexity/changed_javascript_packages'

describe DeployComplexity::ChangedJavascriptPackages do
  let(:old) do
    <<-TXT.gsub(/^\s+/, "")
      {
        "name": "my-package",
        "version": "0.0.0",
        "lockfileVersion": 1,
        "requires": true,
        "dependencies": {
          "@blackberry/pie": {
            "version": "3.1.4",
            "resolved": "npmjs.org/pie",
            "integrity": "sha-pie",
            "dev": true,
            "requires": {}
          },
          "@blueberry/pie": {
            "version": "3.1.4",
            "resolved": "npmjs.org/pie",
            "integrity": "sha-pie",
            "dev": true,
            "requires": {}
          }
        }
      }
    TXT
  end
  subject(:changed_javascript_packages) do
    DeployComplexity::ChangedJavascriptPackages.new(
      file: "file_path",
      old: old,
      new: new
    )
  end

  describe "#changes" do
    context "with no changed packages" do
      let(:new) { old }
      it "returns an empty array" do
        expect(changed_javascript_packages.changes).to eq([])
      end
    end

    context "with changed packages" do
      let(:new) do
        <<-TXT.gsub(/^\s+/, "")
          {
            "name": "my-package",
            "version": "0.0.0",
            "lockfileVersion": 1,
            "requires": true,
            "dependencies": {
              "@blackberry/pie": {
                "version": "3.1.5",
                "resolved": "npmjs.org/pie",
                "integrity": "sha-pie",
                "dev": true,
                "requires": {}
              },
              "@rhubarb/pie": {
                "version": "3.1.4",
                "resolved": "npmjs.org/pie",
                "integrity": "sha-pie",
                "dev": true,
                "requires": {}
              }
            }
          }
        TXT
      end

      it "formats the changes" do
        expect(changed_javascript_packages.changes).to eq(
          [
            "Added @rhubarb/pie: 3.1.4 (file_path)",
            "Removed @blueberry/pie: 3.1.4 (file_path)",
            "Updated @blackberry/pie: 3.1.4 -> 3.1.5 (file_path)"
          ]
        )
      end
    end
  end
end
