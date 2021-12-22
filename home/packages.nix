{ config, lib, pkgs, ... }:

{
  home.sessionPath = [

  ];

  home.packages = with pkgs; [
    broot # better tree

    clang
    curl
    curlie
    httpie
    xh

    docker
    duf # better df
    fd # better find
    moreutils
    procs # better ps
    ripgrep # better grep
    tree
    watch
    wget

    spacevim
  ];
}
