module Verify.GoHTTP where

import Prelude

import Data.Either (Either(..))
import Data.Maybe (fromMaybe)
import Data.Newtype (un)
import Effect (Effect)
import Effect.Aff (Aff, launchAff_)
import Effect.Class (liftEffect)
import Effect.Class.Console (log)
import Go.Net.HTTP (Address(..), QueryName(..), URL(..))
import Go.Net.HTTP as HTTP

main :: Effect Unit
main = launchAff_ do
  started <- HTTP.start (Address "127.0.0.1:0") greet # liftEffect
  case started of
    Left failure -> log ("start failed: " <> show failure)
    Right server -> do
      answered <- HTTP.get (URL ("http://" <> un Address (HTTP.serverAddress server) <> "/?name=Go"))
      case answered of
        Left failure -> log ("get failed: " <> show failure)
        Right response -> log ("status " <> show (HTTP.status response) <> ": " <> HTTP.responseBody response)
      HTTP.shutdown server
      log "shut down"

greet :: HTTP.Request -> Aff HTTP.Response
greet request = pure (HTTP.ok ("hello " <> fromMaybe "stranger" (HTTP.query (QueryName "name") request)))
