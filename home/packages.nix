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
    gdu # better du
    fd # better find
    moreutils
    # procs # better ps
    ripgrep # better grep
    tree
    watch
    wget

    scc # better cloc - code stats
    diff-so-fancy # better diff
    hyperfine # benchmark command


    mediainfo
    libmediainfo
    difftastic

  ];
}
