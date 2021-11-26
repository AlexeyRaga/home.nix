self: super:
let
  installDmgApp = import ../lib/installDmgApp.nix super;
  installZipApp = import ../lib/installZipApp.nix super;
in
{
  rider = installDmgApp rec {
    pname = "Rider";
    description = "Rider";
    homepage = "http://jetbrains.com/rider";
    version = "2021.1.2";

    src = {
      url = "https://download-cf.jetbrains.com/rider/JetBrains.Rider-${version}.dmg";
      sha256 = "1qrmyrmyzkjmggm8q5cycfdhsn4iqh7q9mvbj3harc1379l79x86";
    };
  };

  iterm2 = installZipApp rec {
    pname = "iTerm";
    version = "3_4_6";
    description = "The best terminall client ever";

    homepage = "https://iterm2.com";
    src = {
      url = "https://iterm2.com/downloads/stable/iTerm2-${version}.zip";
      sha256 = "0myb9dz9fnif5w4f2348m6r6ppbxygfjnmzfvcn4mbhpm78jb1h0";
    };
  };

  altair = installDmgApp rec {
    pname = "Altair";
    appName = "Altair GraphQL Client";
    description = "Altair GraphQL Client";
    version = "4.0.11";

    homepage =  "https://altair.sirmuel.design/";
    src = {
      url = "https://github.com/altair-graphql/altair/releases/download/v${version}/altair_${version}_x64_mac.dmg";
      sha256 = "02xym3jxjc90yiws3w3rp5b8hcsh0xlwh44dqdbjcy1d8b0v72yq";
    };
  };
}
