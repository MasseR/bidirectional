with (import <nixpkgs> {});

let bidir = haskellPackages.callPackage ./. {};

in

mkShell {
  name = "shell";
  buildInputs = [
    haskellPackages.cabal-install
    haskellPackages.stylish-haskell
    ghcid
    cabal2nix
    (haskellPackages.ghcWithPackages (_: bidir.buildInputs ++ bidir.propagatedBuildInputs))
  ];
}
