{ ... }:
let
  sources = import ./nix/sources.nix { };
  pkgs = import sources.nixpkgs { };
  lib = pkgs.lib;

  expectVersion = version: pkg:
    let actual = lib.getVersion pkg;
    in assert (lib.assertMsg (builtins.toString actual == version) ''
      Expecting version of ${pkg.name} to be ${version} but got ${actual};
      adjust the expected version or fetch/build the desired version of the package.
    '');
    pkg;

  rubyVersion = lib.fileContents ./.ruby-version;
  bundlerVersion = lib.fileContents ./.bundler-version;

  ruby = pkgs.ruby;
in pkgs.stdenv.mkDerivation {
  name = "deploy-complexity";
  buildInputs = [
    pkgs.git
    (expectVersion rubyVersion pkgs.ruby)
    (expectVersion bundlerVersion (pkgs.bundler.override { inherit ruby; }))
  ];
}
