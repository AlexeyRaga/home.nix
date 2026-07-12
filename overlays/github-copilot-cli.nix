# Override github-copilot-cli with a newer upstream release than what's in
# nixpkgs. To bump: change `version` and replace the four hashes with the
# values from
# https://github.com/github/copilot-cli/releases/download/v<version>/SHA256SUMS.txt
# (the `sha256:<hex>` form accepts the raw hex from that file as-is).
self: super:

let
  version = "1.0.70";

  sources = {
    "x86_64-linux" = {
      name = "copilot-linux-x64";
      hash = "sha256:4edee3cd005254960789329181968b209b17cab47f43ee13c9e071b1f7e33095";
    };
    "aarch64-linux" = {
      name = "copilot-linux-arm64";
      hash = "sha256:1cb358a1a8ac8d0f680b54c6eac990c376043314409a06a5aa4fed0e0a7d3362";
    };
    "x86_64-darwin" = {
      name = "copilot-darwin-x64";
      hash = "sha256:ce2d968b68c1a28690544ff638e762a804943992b5496fb7ec2358fe7f1eee87";
    };
    "aarch64-darwin" = {
      name = "copilot-darwin-arm64";
      hash = "sha256:5f9791561eefe99b3bed25a02eef37dc434327053af05e6150dad7d6aed05a35";
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
