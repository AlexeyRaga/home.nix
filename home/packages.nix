{ config, lib, pkgs, ... }:

{
  home.sessionPath = [

  ];

  home.packages = with pkgs; [
    devenv
    
    tree

    clang

    delta # diff stuff, https://github.com/dandavison/delta
    difftastic # A structural diff that understands syntax.
    diff-so-fancy # better diff

    aria2 # multiprotocol downloader: HTTP/HTTPS/FTP/SFTP/BitTorrent/Metalink
    curl
    wget
    # curlie
    # httpie # HTTP requests tool, Python
    xh # Friendly and fast tool for sending HTTP requests, written in Rust

    docker
    docker-credential-helpers
    lazydocker
    dive # docker images exploration, https://github.com/wagoodman/dive

    duf # better df
    gdu # better du
    fd # better find

    moreutils
    # procs # better ps
    ripgrep # better grep
    ack # find in files, grep-ish, https://linux.die.net/man/1/ack

    watch

    jqp # jq playground, https://github.com/noahgorstein/jqp
    fx # Terminal JSON viewer & processor, https://fx.wtf/

    scc # better cloc - code stats

    hyperfine # benchmark command

    mediainfo
    libmediainfo

    yt-dlp
  ];
}
