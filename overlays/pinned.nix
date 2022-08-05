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
  # _1password = (pinned "_1password" "466c2e342a6887507fb5e58d8d29350a0c4b7488").nixUnstable;
}
