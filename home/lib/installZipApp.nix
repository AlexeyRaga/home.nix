{ lib, pkgs, fetchurl, unzip, ... }:

{ pname
, appname ? pname
, version
, src
, description
, homepage
, postInstall ? ""
, sourceRoot ? "."
, extraBuildInputs ? [ ]
, ...
}:

pkgs.stdenv.mkDerivation {
  pname = pname;
  version = version;
  src = fetchurl src;

  buildInputs = [ unzip ] ++ extraBuildInputs;
  sourceRoot = sourceRoot;
  phases = [
    "unpackPhase"
    "installPhase"
  ];
  installPhase = ''
    mkdir -p "$out/Applications"
    cp -r "${appname}.app" "$out/Applications/${appname}.app"
  '' + postInstall;

  meta = {
    description = description;
    homepage = homepage;
    platforms = lib.platforms.darwin;
  };
}
