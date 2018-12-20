# frozen_string_literal: true

require 'spec_helper'
require 'deploy_complexity/changed_files'

describe ChangedFiles do
  let(:files) do
    <<-TXT.gsub(/^\s+/, "")
      app/assets/images/foo/bar.svg
      app/lib/types/bar.rb
      db/migrate/20121210193522_add_a_to_b.rb
      script/do_the_thing.sh
    TXT
  end

  let(:versioned_url) { "https://github.com/NoRedInk/deploy-complexity/blob/v0.5.0/" }

  describe "#migrations" do
    it "generates a list of links to migration files" do
      changed_files = ChangedFiles.new(files, versioned_url)
      expect(changed_files.migrations)
        .to(eq(["#{versioned_url}db/migrate/20121210193522_add_a_to_b.rb"]))
    end
  end
end
