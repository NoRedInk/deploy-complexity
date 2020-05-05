with import (builtins.fetchTarball rec {
  # grab a hash from here: https://nixos.org/channels/
  name = "nixpkgs-darwin-20.03pre214403.c23427de0d5";
  url =
    "https://github.com/nixos/nixpkgs/archive/c23427de0d501009b9c6d77ff8dda3763c6eb1b4.tar.gz";
  # Hash obtained using `nix-prefetch-url --unpack <url>`
  sha256 = "0fgv4pyzn39y8ibskn37x9cabmg6gflisigr5l45bkplm06bss91";
}) { };
let
  expectVersion = version: pkg:
    let actual = lib.getVersion pkg;
    in assert (lib.assertMsg (builtins.toString actual == version) ''
      Expecting version of ${pkg.name} to be ${version} but got ${actual};
      adjust the expected version or fetch/build the desired version of the package.
    '');
    pkg;

  rubyVersion = lib.fileContents ./.ruby-version;
  bundlerVersion = lib.fileContents ./.bundler-version;

  ruby = ruby_2_5;
in stdenv.mkDerivation {
  name = "deploy-complexity";
  buildInputs = [
    git
    (expectVersion rubyVersion ruby)
    (expectVersion bundlerVersion (bundler.override { inherit ruby; }))
  ];
}
