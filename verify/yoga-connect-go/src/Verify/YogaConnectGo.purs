-- | A gRPC greeter, server and client in one program: the server listens on a free port, the
-- | client calls each kind of method once.
module Verify.YogaConnectGo where

import Prelude

import Control.Monad.Error.Class (try)
import Data.Either (Either(..))
import Data.String as String
import Data.Variant (Variant)
import Data.Variant as Variant
import Demo.Proto.Greeter.V1.Greeter (ChatMessage, Greeting, HelloReply, HelloRequest, ListRequest, greeter)
import Effect (Effect)
import Effect.Class (liftEffect)
import Effect.Exception (Error, message)
import Go.IO (launchIO_)
import Go.IO.Console (log)
import Go.OS (ExitCode(..))
import Go.OS as OS
import Type.Proxy (Proxy(..))
import Yoga.Connect.Client (Connection, client, connect)
import Yoga.Connect.Server (Host(..), Port(..), createServer, listen, reject, serve)
import Yoga.Connect.Status (ConnectError)
import Yoga.Go.HTTP.OmIO (OmIO, liftIO, runOmIO)
import Yoga.OmIO.Strom (Strom)
import Yoga.OmIO.Strom as Strom

main :: Effect Unit
main = do
  server <- createServer
  serve greeter { sayHello, listGreetings, greetEveryone, chat } server
  launchIO_ do
    bound <- listen { host: Host "127.0.0.1", port: Port 0 } server
    connection <- connect ("http://127.0.0.1:" <> show bound.port) # liftEffect
    outcome <- runOmIO unit (talkTo connection)
    case outcome of
      Left failure -> log ("the client failed: " <> describe failure)
      Right _ -> log "done"
    OS.exit (ExitCode 0) # liftEffect

talkTo :: Connection -> OmIO Unit (connectError :: ConnectError) Unit
talkTo connection = do
  reply <- greeterClient.sayHello { name: "Ada" }
  say ("unary: " <> reply.message)
  greeterClient.listGreetings { name: "Grace", count: 1000 }
    # Strom.take 2
    # Strom.forEach \{ index, text } -> say ("server stream: " <> show index <> ". " <> text)
  everyone <- greeterClient.greetEveryone (Strom.fromArray [ { name: "Ada" }, { name: "Grace" } ])
  say ("client stream: " <> everyone.message)
  greeterClient.chat (Strom.fromArray [ { from: "client", text: "hi" } ])
    # Strom.forEach \{ from, text } -> say ("bidi stream: " <> from <> " said " <> text)
  rejected <- try (greeterClient.sayHello { name: "" })
  case rejected of
    Left failure -> say ("rejected: " <> describe failure)
    Right answered -> say ("unexpectedly answered " <> answered.message)
  where
  greeterClient = client greeter connection

sayHello :: forall ctx. HelloRequest -> OmIO ctx (invalidArgument :: String) HelloReply
sayHello { name }
  | name == "" = reject @"invalidArgument" "say who you are"
  | otherwise = pure { message: "Hello, " <> name <> "!" }

listGreetings :: forall ctx. ListRequest -> Strom ctx () Greeting
listGreetings { name, count } = Strom.range 1 (count + 1) # map \index -> { index, text: "hi " <> name }

greetEveryone :: forall ctx. Strom ctx () HelloRequest -> OmIO ctx () HelloReply
greetEveryone people = do
  names <- people # map _.name # Strom.runCollect
  pure { message: "Hello, " <> String.joinWith " and " names <> "!" }

chat :: forall ctx. Strom ctx () ChatMessage -> Strom ctx () ChatMessage
chat incoming = incoming # map \{ text } -> { from: "server", text: String.toUpper text }

say :: forall ctx err. String -> OmIO ctx err Unit
say line = log line # liftIO

describe :: Variant (exception :: Error, connectError :: ConnectError) -> String
describe = Variant.case_
  # Variant.on (Proxy :: _ "exception") message
  # Variant.on (Proxy :: _ "connectError") show
