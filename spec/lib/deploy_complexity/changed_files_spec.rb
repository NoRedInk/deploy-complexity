# frozen_string_literal: true

require 'spec_helper'
require 'deploy_complexity/changed_files'

describe ChangedFiles do
  let(:files) do
    <<-TXT.gsub(/^\s+/, "")
      app/assets/images/foo/bar.svg
      app/lib/types/bar.rb
      frontend/elm.json
      db/migrate/20121210193522_add_a_to_b.rb
      script/do_the_thing.sh
      elm.json
      app/selm.json
    TXT
  end

  subject(:changed_files) { ChangedFiles.new(files, versioned_url) }

  let(:versioned_url) { "https://github.com/NoRedInk/deploy-complexity/blob/v0.5.0/" }

  describe "#migrations" do
    it "generates a list of links to migration files" do
      expect(changed_files.migrations)
        .to(eq(["#{versioned_url}db/migrate/20121210193522_add_a_to_b.rb"]))
    end
  end

  describe "#elm_packages" do
    it "generates a list of paths of elm.json files" do
      expect(changed_files.elm_packages)
        .to eq(["frontend/elm.json", "elm.json"])
    end
  end
end
