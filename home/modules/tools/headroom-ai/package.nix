# Standalone package definition — usable via `callPackage`, which is what makes
# it drop-in for an overlay:
#
#   # ~/.nixpkgs/overlays/headroom.nix
#   final: prev: {
#     headroom-ai = final.callPackage /path/to/package.nix { };
#   }
#
# or, consuming this repo as a flake:  inputs.headroom.overlays.default
{
  lib,
  stdenvNoCC,
  python313,
  cacert,

  # Overridable via callPackage's second arg, e.g.
  #   callPackage ./package.nix { version = "0.29.0"; extras = []; }
  version ? "0.32.0",

  # PyPI extras. [ "all" ] pulls the full ML/RAG stack (torch, opencv,
  # onnxruntime, sentence-transformers, …) — ~140 wheels, several hundred MB.
  # Use [] for just the core CLI.
  extras ? [ "all" ],

  # ── Why two derivations? ──────────────────────────────────────────────────
  # A venv hardcodes its own install path everywhere (script shebangs,
  # bin/activate, pyvenv.cfg, dist-info/RECORD). A fixed-output derivation's
  # $out path is itself derived from the pinned outputHash — so hashing the venv
  # directly never converges: pinning the hash changes $out, which changes the
  # embedded paths, which changes the hash. So we split the network step (a FOD
  # that only downloads wheels — wheel files don't embed $out, so the hash is
  # stable and pins once) from the venv step (an ordinary derivation that
  # installs offline; ordinary derivations handle self-referential $out fine).
  #
  # These pin the *resolved* wheel set, not the resolution. Because only
  # headroom-ai==${version} is constrained, a new release of any transitive dep
  # can change what pip resolves and break a pin with a hash mismatch — rebuild
  # and paste the printed hash. First build on a new system: leave it unset and
  # Nix prints the real hash. For a fully hermetic pin, add a constraints file
  # to the download step.
  wheelHashes ? {
    aarch64-darwin = "sha256-q0KX4E1b0FhCo9TDZT0rNhXtbS+aU7YYaWQSHrXVCh8=";
    # x86_64-linux   = "sha256-...="; # build on that system, paste printed hash
    # aarch64-linux  = "sha256-...=";
  },
}:

let
  system = stdenvNoCC.hostPlatform.system;
  extrasStr = lib.optionalString (extras != [ ]) "[${lib.concatStringsSep "," extras}]";
  spec = "headroom-ai${extrasStr}==${version}";
  wheelHash = wheelHashes.${system} or lib.fakeHash;

  # 1. Download wheels (fixed-output, network-enabled, path-independent → stable).
  wheels = stdenvNoCC.mkDerivation {
    pname = "headroom-ai-wheels";
    inherit version;
    dontUnpack = true;

    nativeBuildInputs = [ python313 cacert ];

    buildPhase = ''
      export HOME=$TMPDIR
      export SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt

      # A throwaway venv just to get a pip binary. --only-binary=:all: forces
      # wheels: pip backtracks to versions that publish prebuilt wheels instead
      # of compiling an sdist (recent litellm builds a Rust bridge → needs cargo
      # + a C compiler this sandbox lacks), and fails loudly if one is missing.
      python -m venv "$TMPDIR/dl"
      mkdir -p "$out"
      "$TMPDIR/dl/bin/pip" download --no-cache-dir --only-binary=:all: \
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
  pname = "headroom-ai";
  inherit version;
  dontUnpack = true;
  dontFixup = true; # prebuilt wheels — skip strip/patchelf

  nativeBuildInputs = [ python313 ];

  passthru = { inherit wheels; }; # `headroom-ai.wheels` — handy for re-pinning

  buildPhase = ''
    export HOME=$TMPDIR

    python -m venv "$out"
    # --no-index + --find-links: resolve strictly against the pinned wheel set,
    # no network. --no-compile skips bytecode caches (embedded source mtimes).
    "$out/bin/pip" install --no-cache-dir --no-index --no-compile \
      --find-links=${wheels} "${spec}"

    find "$out" -depth \( -name __pycache__ -o -name '*.pyc' \) -exec rm -rf {} +

    # Make the build bit-for-bit reproducible: pip records a non-deterministic
    # checksum for console-script wrappers in each dist-info/RECORD (fails
    # `nix build --check`). RECORD is only used by `pip uninstall` — never in a
    # read-only store — and entry points come from entry_points.txt, so dropping
    # it is safe. (If some rare subcommand needs importlib.metadata .files(),
    # remove this line.)
    find "$out" -path '*.dist-info/RECORD' -delete
  '';

  installPhase = "true"; # $out is already the finished venv

  meta = {
    description = "Headroom — the context optimization layer for LLM applications";
    homepage = "https://github.com/headroomlabs-ai/headroom";
    mainProgram = "headroom";
    platforms = lib.attrNames wheelHashes; # only systems we have a pin for
  };
}
