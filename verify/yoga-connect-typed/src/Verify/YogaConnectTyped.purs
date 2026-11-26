-- | A gRPC service as a type: its server and client in one program, an error of its own with an
-- | `Int`, and the first lines of its `.proto`.
module Verify.YogaConnectTyped where

import Prelude

import Control.Monad.Error.Class (try)
import Data.Either (Either(..), either)
import Data.Variant (Variant)
import Data.Variant as Variant
import Effect (Effect)
import Effect.Class (liftEffect)
import Effect.Exception (Error, message)
import Go.IO (launchIO_)
import Go.IO.Console (log)
import Go.OS (ExitCode(..))
import Go.OS as OS
import Yoga.Connect.Om (type (:=), Connection, ConnectError, Handler, Host(..), Message, OmIO, Port(..), ServerStream, Service, Unary, ask, client, connect, createServer, handle, liftIO, listen, printProto, registerServiceWith, reject, runOmIO)
import Yoga.OmIO.Strom as Strom

type Counter = Service "counter.v1.Counter"
  { add :: Unary Amount Amount (tooMuch :: Int)
  , countTo :: ServerStream Amount Amount ()
  }

type Amount = Message { amount :: 1 := Int }

main :: Effect Unit
main = launchIO_ do
  server <- createServer # liftEffect
  registerServiceWith @Counter { start: 40 } { add, countTo } server # liftEffect
  bound <- listen { host: Host "127.0.0.1", port: Port 0 } server
  connection <- connect ("http://127.0.0.1:" <> show (portOf bound.port)) # liftEffect
  outcome <- runOmIO unit (callBoth connection)
  log (either describeFailure (const "done") outcome)
  log (printProto @Counter)
  OS.exit (ExitCode 0) # liftEffect
  where
  portOf (Port number) = number

type Failures = (tooMuch :: Int, connectError :: ConnectError)

callBoth :: Connection -> OmIO Unit Failures Unit
callBoth connection = do
  let counter = client @Counter connection
  { amount } <- counter.add { amount: 2 }
  say ("unary: " <> show amount)
  counted <- counter.countTo { amount: 3 } # Strom.runCollect
  say ("server stream: " <> show (counted <#> _.amount))
  refused <- try (counter.add { amount: 100 })
  say ("rejected: " <> either describeFailure (const "nothing") refused)
  where
  say line = log line # liftIO

add :: Handler (Unary Amount Amount (tooMuch :: Int)) (start :: Int)
add = handle do
  { request: { amount }, start } <- ask
  when (amount > 10) (reject @"tooMuch" amount)
  pure { amount: start + amount }

countTo :: Handler (ServerStream Amount Amount ()) (start :: Int)
countTo = handle do
  { request: { amount } } <- ask
  pure (Strom.range 1 (amount + 1) <#> { amount: _ })

describeFailure :: Variant (exception :: Error | Failures) -> String
describeFailure = Variant.match
  { tooMuch: \amount -> "too much: " <> show amount
  , connectError: show
  , exception: message
  }
