# Override github-copilot-cli with a newer upstream release than what's in
# nixpkgs. To bump: change `version` and replace the four hashes with the
# values from
# https://github.com/github/copilot-cli/releases/download/v<version>/SHA256SUMS.txt
# (the `sha256:<hex>` form accepts the raw hex from that file as-is).
self: super:

let
  version = "1.0.39";

  sources = {
    "x86_64-linux" = {
      name = "copilot-linux-x64";
      hash = "sha256:66ddea6612a5621adc734d6ea2ce150cb85682a3e32f08bf90695fc29374616a";
    };
    "aarch64-linux" = {
      name = "copilot-linux-arm64";
      hash = "sha256:d128ee5cf7d2e7ec6c87511cfcb11f3e072bb679618ca9a465da30f087bfde86";
    };
    "x86_64-darwin" = {
      name = "copilot-darwin-x64";
      hash = "sha256:cbb1f91a8bb7dd7028d2087587715ac4126cab5154396cf4e398f2b759d3a8ef";
    };
    "aarch64-darwin" = {
      name = "copilot-darwin-arm64";
      hash = "sha256:2ab5a564165894103780698a17af9b6016ef5392d6699b0804451f543b0cac54";
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
