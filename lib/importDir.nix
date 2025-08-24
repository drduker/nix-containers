# Import all directories dynamically - based on docker-nixpkgs pattern
{ lib, ... }:

path: importFn:

let
  # Get all directories from the path
  dirs = lib.filterAttrs (_: type: type == "directory") (builtins.readDir path);
  
  # Import each directory and create attribute set
  importedDirs = lib.mapAttrs (name: _: importFn (path + "/${name}")) dirs;
  
in
importedDirs