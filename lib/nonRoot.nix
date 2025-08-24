# Non-root user configuration for container images
{ lib, ... }:

{
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
}