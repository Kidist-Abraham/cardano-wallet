let
  buildDepError = pkg:
    builtins.throw ''
      The Haskell package set does not contain the package: ${pkg} (build dependency).
      
      If you are using Stackage, make sure that you are using a snapshot that contains the package. Otherwise you may need to update the Hackage snapshot you are using, usually by updating haskell.nix.
      '';
  sysDepError = pkg:
    builtins.throw ''
      The Nixpkgs package set does not contain the package: ${pkg} (system dependency).
      
      You may need to augment the system package mapping in haskell.nix so that it can be found.
      '';
  pkgConfDepError = pkg:
    builtins.throw ''
      The pkg-conf packages does not contain the package: ${pkg} (pkg-conf dependency).
      
      You may need to augment the pkg-conf package mapping in haskell.nix so that it can be found.
      '';
  exeDepError = pkg:
    builtins.throw ''
      The local executable components do not include the component: ${pkg} (executable dependency).
      '';
  legacyExeDepError = pkg:
    builtins.throw ''
      The Haskell package set does not contain the package: ${pkg} (executable dependency).
      
      If you are using Stackage, make sure that you are using a snapshot that contains the package. Otherwise you may need to update the Hackage snapshot you are using, usually by updating haskell.nix.
      '';
  buildToolDepError = pkg:
    builtins.throw ''
      Neither the Haskell package set or the Nixpkgs package set contain the package: ${pkg} (build tool dependency).
      
      If this is a system dependency:
      You may need to augment the system package mapping in haskell.nix so that it can be found.
      
      If this is a Haskell dependency:
      If you are using Stackage, make sure that you are using a snapshot that contains the package. Otherwise you may need to update the Hackage snapshot you are using, usually by updating haskell.nix.
      '';
in { system, compiler, flags, pkgs, hsPkgs, pkgconfPkgs, ... }:
  {
    flags = { release = false; };
    package = {
      specVersion = "1.10";
      identifier = { name = "cardano-wallet-shelley"; version = "2020.5.6"; };
      license = "Apache-2.0";
      copyright = "2020 IOHK";
      maintainer = "operations@iohk.io";
      author = "IOHK Engineering Team";
      homepage = "https://github.com/input-output-hk/cardano-wallet";
      url = "";
      synopsis = "Wallet backend protocol-specific bits implemented using Shelley nodes";
      description = "Please see README.md";
      buildType = "Simple";
      isLocal = true;
      };
    components = {
      "library" = {
        depends = [
          (hsPkgs."base" or (buildDepError "base"))
          (hsPkgs."aeson" or (buildDepError "aeson"))
          (hsPkgs."async" or (buildDepError "async"))
          (hsPkgs."bytestring" or (buildDepError "bytestring"))
          (hsPkgs."cardano-api" or (buildDepError "cardano-api"))
          (hsPkgs."cardano-binary" or (buildDepError "cardano-binary"))
          (hsPkgs."cardano-slotting" or (buildDepError "cardano-slotting"))
          (hsPkgs."cardano-wallet-cli" or (buildDepError "cardano-wallet-cli"))
          (hsPkgs."cardano-addresses" or (buildDepError "cardano-addresses"))
          (hsPkgs."cardano-crypto" or (buildDepError "cardano-crypto"))
          (hsPkgs."cardano-wallet-core" or (buildDepError "cardano-wallet-core"))
          (hsPkgs."cardano-config" or (buildDepError "cardano-config"))
          (hsPkgs."cardano-wallet-launcher" or (buildDepError "cardano-wallet-launcher"))
          (hsPkgs."cborg" or (buildDepError "cborg"))
          (hsPkgs."containers" or (buildDepError "containers"))
          (hsPkgs."contra-tracer" or (buildDepError "contra-tracer"))
          (hsPkgs."cryptonite" or (buildDepError "cryptonite"))
          (hsPkgs."directory" or (buildDepError "directory"))
          (hsPkgs."exceptions" or (buildDepError "exceptions"))
          (hsPkgs."ed25519" or (buildDepError "ed25519"))
          (hsPkgs."filepath" or (buildDepError "filepath"))
          (hsPkgs."fmt" or (buildDepError "fmt"))
          (hsPkgs."generic-lens" or (buildDepError "generic-lens"))
          (hsPkgs."io-sim-classes" or (buildDepError "io-sim-classes"))
          (hsPkgs."iohk-monitoring" or (buildDepError "iohk-monitoring"))
          (hsPkgs."memory" or (buildDepError "memory"))
          (hsPkgs."network" or (buildDepError "network"))
          (hsPkgs."network-mux" or (buildDepError "network-mux"))
          (hsPkgs."shelley-spec-ledger" or (buildDepError "shelley-spec-ledger"))
          (hsPkgs."optparse-applicative" or (buildDepError "optparse-applicative"))
          (hsPkgs."ouroboros-consensus" or (buildDepError "ouroboros-consensus"))
          (hsPkgs."ouroboros-consensus-shelley" or (buildDepError "ouroboros-consensus-shelley"))
          (hsPkgs."ouroboros-network" or (buildDepError "ouroboros-network"))
          (hsPkgs."cardano-crypto-class" or (buildDepError "cardano-crypto-class"))
          (hsPkgs."ouroboros-network-framework" or (buildDepError "ouroboros-network-framework"))
          (hsPkgs."process" or (buildDepError "process"))
          (hsPkgs."retry" or (buildDepError "retry"))
          (hsPkgs."servant-server" or (buildDepError "servant-server"))
          (hsPkgs."temporary" or (buildDepError "temporary"))
          (hsPkgs."text" or (buildDepError "text"))
          (hsPkgs."text-class" or (buildDepError "text-class"))
          (hsPkgs."time" or (buildDepError "time"))
          (hsPkgs."transformers" or (buildDepError "transformers"))
          (hsPkgs."unordered-containers" or (buildDepError "unordered-containers"))
          (hsPkgs."warp" or (buildDepError "warp"))
          (hsPkgs."yaml" or (buildDepError "yaml"))
          (hsPkgs."Win32-network" or (buildDepError "Win32-network"))
          ];
        buildable = true;
        };
      exes = {
        "cardano-wallet-shelley" = {
          depends = [
            (hsPkgs."base" or (buildDepError "base"))
            (hsPkgs."cardano-wallet-shelley" or (buildDepError "cardano-wallet-shelley"))
            (hsPkgs."cardano-wallet-cli" or (buildDepError "cardano-wallet-cli"))
            (hsPkgs."cardano-wallet-core" or (buildDepError "cardano-wallet-core"))
            (hsPkgs."cardano-wallet-launcher" or (buildDepError "cardano-wallet-launcher"))
            (hsPkgs."contra-tracer" or (buildDepError "contra-tracer"))
            (hsPkgs."iohk-monitoring" or (buildDepError "iohk-monitoring"))
            (hsPkgs."network" or (buildDepError "network"))
            (hsPkgs."optparse-applicative" or (buildDepError "optparse-applicative"))
            (hsPkgs."text" or (buildDepError "text"))
            (hsPkgs."text-class" or (buildDepError "text-class"))
            (hsPkgs."transformers" or (buildDepError "transformers"))
            ];
          buildable = true;
          };
        };
      tests = {
        "unit" = {
          depends = [
            (hsPkgs."base" or (buildDepError "base"))
            (hsPkgs."bytestring" or (buildDepError "bytestring"))
            (hsPkgs."cardano-wallet-core" or (buildDepError "cardano-wallet-core"))
            (hsPkgs."cardano-crypto-class" or (buildDepError "cardano-crypto-class"))
            (hsPkgs."cardano-addresses" or (buildDepError "cardano-addresses"))
            (hsPkgs."shelley-spec-ledger" or (buildDepError "shelley-spec-ledger"))
            (hsPkgs."memory" or (buildDepError "memory"))
            (hsPkgs."ouroboros-consensus-shelley" or (buildDepError "ouroboros-consensus-shelley"))
            (hsPkgs."cardano-wallet-shelley" or (buildDepError "cardano-wallet-shelley"))
            (hsPkgs."ouroboros-network" or (buildDepError "ouroboros-network"))
            (hsPkgs."hspec" or (buildDepError "hspec"))
            (hsPkgs."QuickCheck" or (buildDepError "QuickCheck"))
            ];
          build-tools = [
            (hsPkgs.buildPackages.hspec-discover or (pkgs.buildPackages.hspec-discover or (buildToolDepError "hspec-discover")))
            ];
          buildable = true;
          };
        "integration" = {
          depends = [
            (hsPkgs."base" or (buildDepError "base"))
            (hsPkgs."aeson" or (buildDepError "aeson"))
            (hsPkgs."async" or (buildDepError "async"))
            (hsPkgs."bytestring" or (buildDepError "bytestring"))
            (hsPkgs."cardano-wallet-cli" or (buildDepError "cardano-wallet-cli"))
            (hsPkgs."cardano-wallet-core" or (buildDepError "cardano-wallet-core"))
            (hsPkgs."cardano-wallet-shelley" or (buildDepError "cardano-wallet-shelley"))
            (hsPkgs."cardano-wallet-core-integration" or (buildDepError "cardano-wallet-core-integration"))
            (hsPkgs."cardano-wallet-launcher" or (buildDepError "cardano-wallet-launcher"))
            (hsPkgs."cardano-wallet-test-utils" or (buildDepError "cardano-wallet-test-utils"))
            (hsPkgs."hspec" or (buildDepError "hspec"))
            (hsPkgs."http-client" or (buildDepError "http-client"))
            (hsPkgs."iohk-monitoring" or (buildDepError "iohk-monitoring"))
            (hsPkgs."temporary" or (buildDepError "temporary"))
            (hsPkgs."text" or (buildDepError "text"))
            ];
          build-tools = [
            (hsPkgs.buildPackages.cardano-wallet-shelley or (pkgs.buildPackages.cardano-wallet-shelley or (buildToolDepError "cardano-wallet-shelley")))
            ];
          buildable = true;
          };
        };
      };
    } // rec { src = (pkgs.lib).mkDefault ../.././lib/shelley; }