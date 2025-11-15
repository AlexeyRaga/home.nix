self: super: {
  gh-copilot-cli = super.buildNpmPackage rec {
    pname = "gh-copilot-cli";
    version = "0.0.358";

    nodejs = super.nodejs_22;

    src = super.fetchzip {
      url = "https://registry.npmjs.org/@github/copilot/-/copilot-${version}.tgz";
      hash = "sha256-+OjC5m5KnZrp0qquMT/Nf4xFoXS/Dz7XBG8djwktYMk=";
    };

    npmDepsHash = "sha256-piJp0VHIoNPQE3gqIZVrIw2HHJffkNgxf2U3PNv6Xiw=";

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