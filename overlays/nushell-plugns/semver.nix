self: super: {
  nushellPlugins = super.nushellPlugins // {
    semver = super.nushellPlugins.semver.overrideAttrs (oldAttrs: {
      
      meta = oldAttrs.meta // {
        platforms = super.lib.platforms.linux ++ super.lib.platforms.darwin;
      };
    });
  };
}