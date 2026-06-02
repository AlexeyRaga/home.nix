# Override github-copilot-cli with a newer upstream release than what's in
# nixpkgs. To bump: change `version` and replace the four hashes with the
# values from
# https://github.com/github/copilot-cli/releases/download/v<version>/SHA256SUMS.txt
# (the `sha256:<hex>` form accepts the raw hex from that file as-is).
self: super:

let
  version = "1.0.52";

  sources = {
    "x86_64-linux" = {
      name = "copilot-linux-x64";
      hash = "sha256:3e32a4d1de31f2cd975d28ca0f79f4868a391478305396263216d3ffd3228f8f";
    };
    "aarch64-linux" = {
      name = "copilot-linux-arm64";
      hash = "sha256:47855ea4db484b62b6fe582d31f12da6f9edf888b16790ec009dac4eced62fb8";
    };
    "x86_64-darwin" = {
      name = "copilot-darwin-x64";
      hash = "sha256:a67362dd56adb514fb69cf76de7875de477824db50307b8be789797677b07ac6";
    };
    "aarch64-darwin" = {
      name = "copilot-darwin-arm64";
      hash = "sha256:0d1d2af7cc28e887dcc7e943bee1b659a1a4cd36dccf8e47cf2a3953c6788d2b";
    };
  };
in
{
  github-copilot-cli = self.callPackage (
    { lib
    , stdenv
    , autoPatchelfHook
    , fetchurl
    , makeBinaryWrapper
    , bash
    , versionCheckHook
    }:
    let
      srcConfig = sources.${stdenv.hostPlatform.system}
        or (throw "github-copilot-cli: unsupported system ${stdenv.hostPlatform.system}");
    in
    stdenv.mkDerivation (finalAttrs: {
      pname = "github-copilot-cli";
      inherit version;

      src = fetchurl {
        url = "https://github.com/github/copilot-cli/releases/download/v${finalAttrs.version}/${srcConfig.name}.tar.gz";
        inherit (srcConfig) hash;
      };

      nativeBuildInputs = [
        makeBinaryWrapper
      ]
      ++ lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];
      buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ stdenv.cc.cc.lib ];
      sourceRoot = ".";
      dontStrip = true;

      installPhase = ''
        runHook preInstall
        install -Dm755 copilot $out/libexec/copilot
        runHook postInstall
      '';

      postInstall = ''
        makeWrapper $out/libexec/copilot $out/bin/copilot \
          --add-flags "--no-auto-update" \
          --prefix PATH : "${lib.makeBinPath [ bash ]}"
      '';

      nativeInstallCheckInputs = [ versionCheckHook ];
      doInstallCheck = !stdenv.hostPlatform.isDarwin;

      meta = {
        description = "GitHub Copilot CLI brings the power of Copilot coding agent directly to your terminal";
        homepage = "https://github.com/github/copilot-cli";
        changelog = "https://github.com/github/copilot-cli/releases/tag/v${finalAttrs.version}";
        license = lib.licenses.unfree;
        mainProgram = "copilot";
        platforms = [
          "x86_64-linux"
          "aarch64-linux"
          "x86_64-darwin"
          "aarch64-darwin"
        ];
      };
    })
  ) { };
}
