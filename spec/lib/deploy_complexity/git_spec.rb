# frozen_string_literal: true

require 'spec_helper'
require 'deploy_complexity/git'

describe DeployComplexity::Git do
  describe ".safe_name" do
    subject { DeployComplexity::Git.method(:safe_name) }
    its(['origin/master']) { is_expected.to eq 'master' }
    its(["origin/master\n"]) { is_expected.to eq 'master' }
    its(["origin/master\n\n"]) { is_expected.to eq 'master' }
    its(['origin/team/branch']) { is_expected.to eq 'team/branch' }
    its(['team/branch']) { is_expected.to eq 'team/branch' }
    its(["team/branch\n"]) { is_expected.to eq "team/branch" }
    its(['team/branch/a']) { is_expected.to eq 'team/branch/a' }
    its([nil]) { is_expected.to be_nil }
  end
end
