{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedLabels #-}

module Test.Integration.Scenario.CLI.Mnemonics
    ( spec
    ) where

import Prelude

import Control.Monad
    ( forM_ )
import Data.List
    ( length )
import Data.Text
    ( Text )
import System.Command
    ( Exit (..), Stderr (..), Stdout (..) )
import System.Exit
    ( ExitCode (..) )
import Test.Hspec
    ( SpecWith, describe, it )
import Test.Hspec.Expectations.Lifted
    ( shouldBe, shouldContain )
import Test.Integration.Framework.DSL
    ( cardanoWalletCLI, cardanoWalletLauncherCLI, generateMnemonicsViaCLI )

import qualified Data.Text as T

version :: Text
version = "2019.5.24"

spec :: SpecWith ()
spec = do
    it "CLI - Shows version" $  do
        (Exit c, Stdout out) <- cardanoWalletCLI ["--version"]
        let v = T.dropWhileEnd (== '\n') (T.pack out)
        v `shouldBe` version
        c `shouldBe` ExitSuccess

    it "CLI - cardano-wallet-launcher shows help on bad argument" $  do
        (Exit c, Stdout out) <- cardanoWalletLauncherCLI ["--bad arg"]
        out `shouldContain` "cardano-wallet-launcher"
        c `shouldBe` ExitFailure 1

    describe "CLI - cardano-wallet-launcher shows help with" $  do
        let test option = it option $ do
                (Exit c, Stdout out) <- cardanoWalletLauncherCLI [option]
                out `shouldContain` "cardano-wallet-launcher"
                c `shouldBe` ExitSuccess
        forM_ ["-h", "--help"] test

    it "CLI - cardano-wallet shows help on bad argument" $  do
        (Exit c, Stdout out) <- cardanoWalletCLI ["--bad arg"]
        out `shouldContain` "Cardano Wallet CLI"
        c `shouldBe` ExitFailure 1

    describe "CLI - cardano-wallet shows help with" $  do
        let test option = it option $ do
                (Exit c, Stdout out) <- cardanoWalletCLI [option]
                out `shouldContain` "Cardano Wallet CLI"
                c `shouldBe` ExitSuccess
        forM_ ["-h", "--help"] test

    it "MNEMONICS - Can generate mnemonics with default size" $  do
        (Exit c, Stdout out) <- generateMnemonicsViaCLI []
        length (words out) `shouldBe` 15
        c `shouldBe` ExitSuccess

    describe "MNEMONICS - Can generate mnemonics with different sizes" $ do
        let test size = it ("--size=" <> show size) $ do
                (Exit c, Stdout out) <-
                    generateMnemonicsViaCLI ["--size", show size]
                length (words out) `shouldBe` size
                c `shouldBe` ExitSuccess
        forM_ [9, 12, 15, 18, 21, 24] test

    describe "MNEMONICS - It can't generate mnemonics with an invalid size" $ do
        let sizes =
                ["15.5", "3", "6", "14", "abc", "👌", "0", "~!@#%" , "-1000", "1000"]
        forM_ sizes $ \(size) -> it ("--size=" <> size) $ do
            (Exit c, Stdout out, Stderr err) <-
                generateMnemonicsViaCLI ["--size", size]
            c `shouldBe` ExitFailure 1
            err `shouldBe`
                "Invalid mnemonic size. Expected one of: 9,12,15,18,21,24\n"
            out `shouldBe` mempty