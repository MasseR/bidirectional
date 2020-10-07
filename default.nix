{ mkDerivation, base, profunctors, stdenv }:
mkDerivation {
  pname = "bidirectional";
  version = "0.1.0.0";
  src = ./.;
  libraryHaskellDepends = [ base profunctors ];
  testHaskellDepends = [ base ];
  license = stdenv.lib.licenses.bsd3;
}
