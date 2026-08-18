# Standalone package definition — usable via `callPackage`, which is what makes
# it drop-in for an overlay:
#
#   # ~/.nixpkgs/overlays/serena.nix
#   final: prev: {
#     serena = final.callPackage /path/to/package.nix { };
#   }
#
# Structurally identical to ../headroom-ai/package.nix; see that file for the
# long-form rationale behind the two-derivation split (recapped briefly below).
{
  lib,
  stdenvNoCC,
  python313,
  cacert,

  # Overridable via callPackage's second arg, e.g.
  #   callPackage ./package.nix { version = "1.7.0"; }
  version ? "1.7.0",

  # Dependencies that publish no wheel on PyPI and so must come as an sdist and
  # be built at install time. proxy_tools (via pywebview → the dashboard's
  # native window) is an ancient sdist-only package. Everything else is forced
  # to `--only-binary`, so a *new* sdist-only dependency fails the build loudly
  # rather than silently compiling something in the sandbox.
  sdistPackages ? [ "proxy_tools" ],

  # ── Why two derivations? ──────────────────────────────────────────────────
  # A venv hardcodes its own install path everywhere, so hashing it directly
  # never converges: pinning the hash changes $out, which changes the embedded
  # paths, which changes the hash. So the network step (a fixed-output
  # derivation that only downloads wheels — wheel files don't embed $out, so
  # the hash pins once) is split from the venv step (an ordinary derivation
  # that installs offline).
  #
  # Unlike headroom, Serena exact-pins every one of its direct dependencies in
  # pyproject.toml (`requests==2.33.0`, `mcp==1.28.1`, …), so a new release of
  # a transitive dep is much less likely to shift what pip resolves and break
  # the pin. If it does happen, rebuild and paste the printed hash. First build
  # on a new system: leave it unset and Nix prints the real hash.
  wheelHashes ? {
    aarch64-darwin = "sha256-mZq3z7d+HYXNKuu/URQV2tVSXhmFbwSVRYISmCg8QMs=";
    # x86_64-linux   = "sha256-...="; # build on that system, paste printed hash
    # aarch64-linux  = "sha256-...=";
  },
}:

let
  system = stdenvNoCC.hostPlatform.system;
  # Serena requires >=3.11,<3.15; python313 sits comfortably inside that.
  spec = "serena-agent==${version}";
  wheelHash = wheelHashes.${system} or lib.fakeHash;

  # pip resolves --no-binary per-package ahead of a blanket --only-binary=:all:,
  # so this reads as "wheels for everything except these".
  noBinaryFlag = lib.optionalString (sdistPackages != [ ])
    "--no-binary=${lib.concatStringsSep "," sdistPackages}";

  # 1. Download wheels (fixed-output, network-enabled, path-independent → stable).
  wheels = stdenvNoCC.mkDerivation {
    pname = "serena-agent-wheels";
    inherit version;
    dontUnpack = true;

    nativeBuildInputs = [ python313 cacert ];

    buildPhase = ''
      export HOME=$TMPDIR
      export SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt

      # A throwaway venv just to get a pip binary. --only-binary=:all: forces
      # wheels rather than compiling sdists in a sandbox that has no compiler,
      # and fails loudly if some dependency ships no wheel for this platform.
      python -m venv "$TMPDIR/dl"
      mkdir -p "$out"
      "$TMPDIR/dl/bin/pip" download --no-cache-dir \
        --only-binary=:all: ${noBinaryFlag} \
        --dest "$out" "${spec}"
    '';

    installPhase = "true";

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = wheelHash;
  };
in
# 2. Build the venv offline from those wheels (ordinary derivation).
stdenvNoCC.mkDerivation {
  pname = "serena";
  inherit version;
  dontUnpack = true;
  dontFixup = true; # prebuilt wheels — skip strip/patchelf

  nativeBuildInputs = [ python313 ];

  passthru = { inherit wheels; }; # `serena.wheels` — handy for re-pinning

  buildPhase = ''
    export HOME=$TMPDIR

    # Building the sdist-only dependencies offline rules out PEP 517 build
    # isolation, which would try to fetch setuptools from PyPI. Hand pip
    # nixpkgs' setuptools instead of adding it to the pinned wheel set — an
    # unpinned setuptools in there would reshuffle the FOD hash on every
    # upstream setuptools release.
    export PYTHONPATH=${python313.pkgs.setuptools}/${python313.sitePackages}:${python313.pkgs.wheel}/${python313.sitePackages}

    python -m venv "$out"
    # --no-index + --find-links: resolve strictly against the pinned wheel set,
    # no network. --no-compile skips bytecode caches (embedded source mtimes).
    "$out/bin/pip" install --no-cache-dir --no-index --no-compile \
      --no-build-isolation --find-links=${wheels} "${spec}"

    find "$out" -depth \( -name __pycache__ -o -name '*.pyc' \) -exec rm -rf {} +

    # Make the build bit-for-bit reproducible: pip records a non-deterministic
    # checksum for console-script wrappers in each dist-info/RECORD (fails
    # `nix build --check`). RECORD is only used by `pip uninstall` — never in a
    # read-only store — and entry points come from entry_points.txt, so dropping
    # it is safe.
    find "$out" -path '*.dist-info/RECORD' -delete
  '';

  installPhase = "true"; # $out is already the finished venv

  meta = {
    description = "Serena — a coding agent toolkit turning an LLM into a semantic code assistant";
    homepage = "https://github.com/oraios/serena";
    mainProgram = "serena";
    platforms = lib.attrNames wheelHashes; # only systems we have a pin for
  };
}
