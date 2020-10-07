with (import <nixpkgs> {});

let bidir = haskellPackages.callPackage ./. {};

in

mkShell {
  name = "shell";
  buildInputs = [
    haskellPackages.cabal-install
    ghcid
    cabal2nix
    (haskellPackages.ghcWithPackages (_: bidir.buildInputs ++ bidir.propagatedBuildInputs))
  ];
}
