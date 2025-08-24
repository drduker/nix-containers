# Non-root user configuration for container images
{ lib, ... }:

rec {
  # Standard non-root user configuration
  user = {
    uid = 1000;
    gid = 1000; 
    name = "nonroot";
  };
  
  # User string for container config
  userString = "1000:1000";
  
  # Standard environment variables for non-root user
  userEnv = [
    "HOME=/home/nonroot"
    "USER=nonroot"
  ];
  
  # Default container config for non-root users (without Cmd - needs to be added per image)
  defaultConfig = {
    User = userString;
    WorkingDir = "/workspace";
  };
  
  # Function to create default user environment
  mkDefaultUserEnv = pkgs: extraDirs:
    pkgs.callPackage ./mkUserEnvironment.nix {} {
      inherit user;
      extraDirs = [ "/workspace" ] ++ (if extraDirs == null then [] else extraDirs);
    };
}