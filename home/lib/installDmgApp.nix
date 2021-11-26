{ lib, pkgs, fetchurl, undmg, ... }:

{ pname
, appName ? pname
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

  buildInputs = [ undmg ] ++ extraBuildInputs;
  sourceRoot = sourceRoot;
  phases = [
    "unpackPhase"
    "installPhase"
  ];
  installPhase = ''
    mkdir -p "$out/Applications"
    cp -r "${appName}.app" "$out/Applications/${appName}.app"
  '' + postInstall;

  meta = {
    description = description;
    homepage = homepage;
    maintainers = [
      lib.maintainers.akoppela
    ];
    platforms = lib.platforms.darwin;
  };
}
