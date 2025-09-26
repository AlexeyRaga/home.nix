self: super: {
  gh-copilot-cli = super.buildNpmPackage rec {
    pname = "gh-copilot-cli";
    version = "0.0.327";

    nodejs = super.nodejs_22;

    src = super.fetchzip {
      url = "https://registry.npmjs.org/@github/copilot/-/copilot-${version}.tgz";
      hash = "sha256-BQhYegt4Rqnzd13BCpGD0U0/Ac9WGgryHOt3tptk06s=";
    };

    npmDepsHash = "sha256-GqJlDnTuRYNG3puAFH4DRdUw+NaYS6ZALOVrim0qbhE=";

    postPatch = ''
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