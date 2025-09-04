self: super: {
  nushellPlugins = super.nushellPlugins // {
    secret = super.rustPlatform.buildRustPackage rec {
      pname = "nu_plugin_secret";
      version = "0.3.0";

      src = super.fetchFromGitHub {
        owner = "nushell-works";
        repo = "nu_plugin_secret";
        rev = "v${version}";
        hash = "sha256-Yv6xZcHf77VjbsKWaeWuaH85Bk8uf4bjrryXQzL76kM="; # Replace with actual hash
      };

      cargoHash = "sha256-wqJZn9VwcOW9Pro1dWWqyIEb9LCj3B1EVfjxr0viKvs="; # Replace with actual hash

      nativeBuildInputs = with super; [ pkg-config ];
      buildInputs = with super; [ openssl ];

      meta = with super.lib; {
        description = "A nushell plugin to manage secrets";
        homepage = "https://github.com/nushell-works/nu_plugin_secret";
        license = licenses.mit;
        maintainers = [];
        mainProgram = "nu_plugin_secret";
      };
    };
  };
}