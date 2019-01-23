# frozen_string_literal: true

require 'spec_helper'
require 'deploy_complexity/changed_files'

describe DeployComplexity::ChangedFiles do
  let(:files) do
    <<-TXT.gsub(/^\s+/, "")
      app/assets/images/foo/bar.svg
      app/lib/types/bar.rb
      frontend/elm.json
      db/migrate/20121210193522_add_a_to_b.rb
      script/do_the_thing.sh
      elm.json
      app/selm.json
      Gemfile.lock
      Gemfile.locknessmonster
      engine/Gemfile.lock
      package-lock.json
      packaged-socks.json
      engine/package-lock.json
    TXT
  end

  subject(:changed_files) { DeployComplexity::ChangedFiles.new(files, versioned_url) }

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

  describe "#ruby_dependencies" do
    it "generates a list of paths of Gemfile.lock files" do
      expect(changed_files.ruby_dependencies)
        .to eq(["Gemfile.lock", "engine/Gemfile.lock"])
    end
  end

  describe "#javascript_dependencies" do
    it "generates a list of paths of package-lock.json files" do
      expect(changed_files.javascript_dependencies)
        .to eq(["package-lock.json", "engine/package-lock.json"])
    end
  end
end
