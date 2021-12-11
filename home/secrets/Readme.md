# A common place for secrets

Everything in this folder (except this document) is supposed to be git ignored and should not be committed to the repository.

Example:

```nix
{
  github = {
    userName = "<github-user-name>";
    token = "<github-api-token>";
  };

  aws = {
    profiles = {
      default = {
        accessKeyId = "AKI...";
        accessSecretKey = "345..."; }
    };
  };
}
```
