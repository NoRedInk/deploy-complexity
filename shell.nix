with import (builtins.fetchTarball rec {
  # grab a hash from here: https://nixos.org/channels/
  name = "nixpkgs-darwin-18.09pre153231.25d0880528d";
  url = "https://github.com/nixos/nixpkgs/archive/25d0880528dcf0f79221b4f16ce64245dc068a84.tar.gz";
  # Hash obtained using `nix-prefetch-url --unpack <url>`
  sha256 = "0f1w4dpyd2pdx48bkhj2c4k2868mbvc2b9kr5qbxi05brzp0nk5l";
}) {};

stdenv.mkDerivation {
  name = "deploy-complexity";
  buildInputs = [
    git
    ruby
    bundler
  ];
}
