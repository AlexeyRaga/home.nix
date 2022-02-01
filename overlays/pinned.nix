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
  # pinned to this version because the latest one is broken: its unit tests fail.
  # awscli = (pinned "awscli" "89f196fe781c53cb50fef61d3063fa5e8d61b6e5").awscli;
  nix26 = (pinned "nix" "fd7729c1451e66c48d3cef89fc8106d6ca2bb978").nixUnstable;
}
