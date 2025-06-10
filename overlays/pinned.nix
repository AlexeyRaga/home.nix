self: super:

let
  # a function that takes a descriptive name and a hash of nixpkgs-unstable to pin
  # and returns the channel at that version
  pinned = name: hash:
    import
      (builtins.fetchGit {
        # Descriptive name to make the store path easier to identify
        name = "pinned-${name}";
        url = "https://github.com/NixOS/nixpkgs/";
        ref = "refs/heads/nixpkgs-unstable";
        rev = hash;
      })
      { };

in
{

  # pin nix itself to 2.6 because 2.7 fails to build on MacOS.
  # nix26 = (pinned "nix" "fd7729c1451e66c48d3cef89fc8106d6ca2bb978").nixUnstable;
  # _1password-cli = (pinned "_1password-cli" "21808d22b1cda1898b71cf1a1beb524a97add2c4").nixUnstable;
}
