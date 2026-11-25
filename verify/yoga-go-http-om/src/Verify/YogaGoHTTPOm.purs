-- | A typed route served by yoga-go-http-om, asked for over HTTP by go-http's client.
module Verify.YogaGoHTTPOm where

import Prelude

import Data.Either (Either(..))
import Effect (Effect)
import Effect.Aff (Aff, launchAff_)
import Effect.Class.Console (log)
import Go.IO (toAff)
import Go.Net.HTTP (URL(..))
import Go.Net.HTTP as HTTP
import Yoga.Go.HTTP.Om (Handler, Host(..), Port(..), createServer, defaultServerOptions, handle, listen, registerAPI, reject, respond)
import Yoga.Go.HTTP.Om.Route (GET, Route)
import Yoga.Go.HTTP.Om.Server (closeAff)
import Yoga.HTTP.API.Path (type (/), type (:))
import Yoga.Om (ask)

type User = { id :: Int, name :: String }

type GetUser = Route GET ("users" / "id" : Int) {} (ok :: { body :: User }, notFound :: { body :: { error :: String } })

type API = { getUser :: GetUser }

main :: Effect Unit
main = do
  server <- createServer defaultServerOptions
  registerAPI @API { getUser } server
  launchAff_ do
    address <- listen { host: Host "127.0.0.1", port: Port 0 } server # toAff
    let base = "http://127.0.0.1:" <> show address.port
    fetchAndLog (base <> "/users/42")
    fetchAndLog (base <> "/users/7")
    fetchAndLog (base <> "/users/abc")
    closeAff server
  where
  fetchAndLog url = statusAndBody url >>= log

getUser :: Handler GetUser ()
getUser = handle do
  { path } <- ask
  if path.id == 42 then respond @"ok" { id: 42, name: "Alice" }
  else reject @"notFound" { error: "no user " <> show path.id }

statusAndBody :: String -> Aff String
statusAndBody url = HTTP.get (URL url) <#> case _ of
  Left failure -> "get failed: " <> show failure
  Right response -> show (HTTP.status response) <> " " <> HTTP.responseBody response
