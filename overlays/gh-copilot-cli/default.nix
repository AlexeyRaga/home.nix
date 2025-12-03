self: super: {
  gh-copilot-cli = super.buildNpmPackage rec {
    pname = "gh-copilot-cli";
    version = "0.0.365";

    nodejs = super.nodejs_22;

    src = super.fetchzip {
      url = "https://registry.npmjs.org/@github/copilot/-/copilot-${version}.tgz";
      hash = "sha256-tOsF3B1GB7/Gs9E8dw/P2SCcrmjIjYj/kfP6wWqBEUA=";
    };

    npmDepsHash = "sha256-kSvaZZlPisLL7nPkrnjNAKgy3cPK5OV8V3t4pz9HMh8=";

    postPatch = ''
      mkdir -p node_modules
      cp ${./package-lock.json} package-lock.json
    '';

    dontNpmBuild = true;

    AUTHORIZED = "1";

    passthru.updateScript = ./update.sh;

    meta = with super.lib; {
      description = "The power of GitHub Copilot, now in your terminal.";
      homepage = "https://github.com/github/copilot-cli";
      mainProgram = "copilot";
    };
  };
}