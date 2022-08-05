{ config, lib, pkgs, ... }:

{
  home.sessionPath = [

  ];

  home.packages = with pkgs; [
    broot # better tree

    clang
    curl
    # curlie
    delta
    httpie
    xh

    docker
    docker-credential-helpers
    duf # better df
    fd # better find
    moreutils
    # procs # better ps
    ripgrep # better grep
    tree
    watch
    wget

    mediainfo
    libmediainfo
    difftastic

  ];
}
