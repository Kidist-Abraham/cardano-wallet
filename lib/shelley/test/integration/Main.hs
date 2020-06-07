{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TupleSections #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}

{-# OPTIONS_GHC -fno-warn-orphans #-}

module Main where

import Prelude

import Cardano.BM.Data.Severity
    ( Severity (..) )
import Cardano.BM.Trace
    ( Trace, logInfo )
import Cardano.CLI
    ( Port (..), withLogging )
import Cardano.Launcher
    ( ProcessHasExited (..) )
import Cardano.Startup
    ( withUtf8Encoding )
import Cardano.Wallet.Api.Server
    ( Listen (..) )
import Cardano.Wallet.Api.Types
    ( ApiByronWallet, ApiWallet, WalletStyle (..) )
import Cardano.Wallet.Network.Ports
    ( unsafePortNumber )
import Cardano.Wallet.Primitive.AddressDerivation
    ( NetworkDiscriminant (..) )
import Cardano.Wallet.Primitive.CoinSelection
    ( CoinSelection (..) )
import Cardano.Wallet.Primitive.Fee
    ( Fee (..), computeFee )
import Cardano.Wallet.Primitive.Types
    ( Address (..)
    , Coin (..)
    , FeePolicy (..)
    , Hash (..)
    , NetworkParameters (..)
    , ProtocolParameters (..)
    , SyncTolerance (..)
    , TxIn (..)
    , TxOut (..)
    , TxParameters (..)
    )
import Cardano.Wallet.Shelley
    ( serveWallet, setupTracers, tracerSeverities )
import Cardano.Wallet.Shelley.Compatibility
    ( Shelley )
import Cardano.Wallet.Shelley.Faucet
    ( initFaucet )
import Cardano.Wallet.Shelley.Launch
    ( withCardanoNode )
import Cardano.Wallet.Shelley.Transaction
    ( _estimateSize )
import Control.Concurrent.Async
    ( race )
import Control.Concurrent.MVar
    ( newEmptyMVar, putMVar, takeMVar )
import Control.Exception
    ( throwIO )
import Control.Monad
    ( forM_, void )
import Data.Proxy
    ( Proxy (..) )
import Data.Text
    ( Text )
import Network.HTTP.Client
    ( defaultManagerSettings
    , managerResponseTimeout
    , newManager
    , responseTimeoutMicro
    )
import Numeric.Natural
    ( Natural )
import System.IO
    ( BufferMode (..), hSetBuffering, stdout )
import System.IO.Temp
    ( withSystemTempDirectory )
import System.Random
    ( mkStdGen, randoms )
import Test.Hspec
    ( Spec, SpecWith, after, describe, hspec, parallel )
import Test.Hspec.Extra
    ( aroundAll )
import Test.Integration.Framework.DSL
    ( Context (..)
    , Headers (..)
    , KnownCommand (..)
    , Payload (..)
    , TxDescription (..)
    , request
    , unsafeRequest
    )
import Test.Utils.Paths
    ( getTestData )

import qualified Cardano.Wallet.Api.Link as Link
import qualified Data.Aeson as Aeson
import qualified Data.ByteString as BS
import qualified Data.Text as T
import qualified Test.Integration.Scenario.API.Network as Network
import qualified Test.Integration.Scenario.API.Shelley.Addresses as Addresses
import qualified Test.Integration.Scenario.API.Shelley.HWWallets as HWWallets
import qualified Test.Integration.Scenario.API.Shelley.Transactions as Transactions
import qualified Test.Integration.Scenario.API.Shelley.Wallets as Wallets
import qualified Test.Integration.Scenario.CLI.Keys as KeyCLI
import qualified Test.Integration.Scenario.CLI.Miscellaneous as MiscellaneousCLI
import qualified Test.Integration.Scenario.CLI.Mnemonics as MnemonicsCLI
import qualified Test.Integration.Scenario.CLI.Network as NetworkCLI
import qualified Test.Integration.Scenario.CLI.Port as PortCLI
import qualified Test.Integration.Scenario.CLI.Shelley.Addresses as AddressesCLI
import qualified Test.Integration.Scenario.CLI.Shelley.HWWallets as HWWalletsCLI
import qualified Test.Integration.Scenario.CLI.Shelley.Transactions as TransactionsCLI
import qualified Test.Integration.Scenario.CLI.Shelley.Wallets as WalletsCLI

-- | Define the actual executable name for the bridge CLI
instance KnownCommand Shelley where
    commandName = "cardano-wallet-shelley"

main :: forall t . (t ~ Shelley) => IO ()
main = withUtf8Encoding $ withLogging Nothing Info $ \(_, tr) -> do
    hSetBuffering stdout LineBuffering
    hspec $ do
        describe "No backend required" $ do
            describe "Mnemonics CLI tests" $ parallel (MnemonicsCLI.spec @t)
            describe "Miscellaneous CLI tests" $ parallel (MiscellaneousCLI.spec @t)
            describe "Key CLI tests" $ parallel (KeyCLI.spec @t)
        describe "API Specifications" $ specWithServer tr $ do
            Addresses.spec
            Transactions.spec
            Wallets.spec
            HWWallets.spec
            Network.spec
        describe "CLI Specifications" $ specWithServer tr $ do
            AddressesCLI.spec
            TransactionsCLI.spec
            WalletsCLI.spec
            HWWalletsCLI.spec
            PortCLI.spec @t
            NetworkCLI.spec

specWithServer
    :: Trace IO Text
    -> SpecWith (Context Shelley)
    -> Spec
specWithServer tr = aroundAll withContext . after tearDown
  where
    networkDiscriminant = Mainnet
    withContext :: (Context Shelley -> IO ()) -> IO ()
    withContext action = do
        ctx <- newEmptyMVar
        let setupContext np wAddr = do
                let baseUrl = "http://" <> T.pack (show wAddr) <> "/"
                logInfo tr baseUrl
                let sixtySeconds = 60*1000*1000 -- 60s in microseconds
                manager <- (baseUrl,) <$> newManager (defaultManagerSettings
                    { managerResponseTimeout =
                        responseTimeoutMicro sixtySeconds
                    })
                faucet <- initFaucet
                putMVar ctx $ Context
                    { _cleanup = pure ()
                    , _manager = manager
                    , _walletPort = Port . fromIntegral $ unsafePortNumber wAddr
                    , _faucet = faucet
                    , _feeEstimator = mkFeeEstimator
                        $ getFeePolicy
                        $ txParameters
                        $ protocolParameters np
                    , _networkParameters = np
                    , _network = networkDiscriminant
                    , _target = Proxy
                    }
        race (takeMVar ctx >>= action) (withServer setupContext) >>=
            either pure (throwIO . ProcessHasExited "integration")

    withServer action =
        withCardanoNode tr $(getTestData) Info $ \socketPath block0 (gp,vData) ->
        withSystemTempDirectory "cardano-wallet-databases" $ \db -> do
            serveWallet @(IO Shelley)
                networkDiscriminant
                (setupTracers (tracerSeverities (Just Info)) tr)
                (SyncTolerance 10)
                (Just db)
                "127.0.0.1"
                ListenOnRandomPort
                Nothing
                socketPath
                block0
                (gp, vData)
                (action gp)

    -- | teardown after each test (currently only deleting all wallets)
    tearDown :: Context t -> IO ()
    tearDown ctx = do
        (_, byronWallets) <- unsafeRequest @[ApiByronWallet] ctx
            (Link.listWallets @'Byron) Empty
        forM_ byronWallets $ \w -> void $ request @Aeson.Value ctx
            (Link.deleteWallet @'Byron w) Default Empty
        (_, wallets) <- unsafeRequest @[ApiWallet] ctx
            (Link.listWallets @'Shelley) Empty
        forM_ wallets $ \w -> void $ request @Aeson.Value ctx
            (Link.deleteWallet @'Shelley w) Default Empty

mkFeeEstimator :: FeePolicy -> TxDescription -> (Natural, Natural)
mkFeeEstimator policy = \case
    PaymentDescription nInps nOuts nChgs ->
        let
            inps = take nInps
                [ ( TxIn (genTxId ix) ix
                  , TxOut (Address mempty) minBound
                  )
                | ix <- [0..]
                ]

            outs =
                replicate (nOuts + nChgs) (Coin minBound)

            size = _estimateSize $ CoinSelection inps [] outs

            fee = fromIntegral $ getFee $ computeFee policy size
        in
            ( fee, fee )

    DelegDescription{} ->
        error "mkFeeEstimator: can't estimate fee for certificate in Byron!"
  where
    genTxId i = Hash $ BS.pack $ take 32 $ randoms $ mkStdGen (fromIntegral i)
