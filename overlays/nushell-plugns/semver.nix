self: super: {
  nushellPlugins = super.nushellPlugins // {
    semver = super.nushellPlugins.semver.overrideAttrs (oldAttrs: {
      version = "0.11.6";
      
      src = super.fetchFromGitHub {
        owner = "abusch";
        repo = "nu_plugin_semver";
        tag = "v0.11.6";
        hash = "sha256-JF+aY7TW0NGo/E1eFVpBZQoxLxuGja8DSoJy4xgi1Lk=";
      };
      
      cargoHash = "sha256-609w/7vmKcNv1zSfd+k6TTeU2lQuzHX3W5Y8EqKIiAM=";
      
      meta = oldAttrs.meta // {
        platforms = super.lib.platforms.linux ++ super.lib.platforms.darwin;
      };
    });
  };
}