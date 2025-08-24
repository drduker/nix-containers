# Create non-root user environment for containers
{ pkgs, ... }:

{ user ? { uid = 1000; gid = 1000; name = "nonroot"; }
, workingDir ? "/workspace"
, extraDirs ? []
, ...
}:

let
  # Create user and group files
  passwdFile = pkgs.writeText "passwd" ''
    root:x:0:0:root:/root:/bin/bash
    ${user.name}:x:${toString user.uid}:${toString user.gid}:${user.name}:/home/${user.name}:/bin/bash
  '';

  groupFile = pkgs.writeText "group" ''
    root:x:0:
    ${user.name}:x:${toString user.gid}:
  '';

  # Create directory structure with proper permissions
  userDirs = pkgs.runCommand "user-dirs" {} ''
    mkdir -p $out/tmp
    mkdir -p $out/home/${user.name}
    mkdir -p $out${workingDir}
    
    # Create extra directories
    ${pkgs.lib.concatMapStringsSep "\n" (dir: "mkdir -p $out${dir}") extraDirs}

    # Set permissions
    chmod 1777 $out/tmp
    chmod 755 $out/home/${user.name}
    chmod 755 $out${workingDir}
    ${pkgs.lib.concatMapStringsSep "\n" (dir: "chmod 755 $out${dir}") extraDirs}
  '';

in
# Return user files that can be included in copyToRoot
pkgs.runCommand "user-environment" {} ''
  mkdir -p $out/etc
  cp ${passwdFile} $out/etc/passwd
  cp ${groupFile} $out/etc/group
  chmod 644 $out/etc/passwd $out/etc/group
  
  # Copy directory structure
  cp -r ${userDirs}/* $out/
''