-- | Two layers wired with `provide`, built in a scope: the database layer reads the config the
-- | other one provides, and its finalizer runs when the scope closes.
module Verify.YogaOmLayer where

import Prelude

import Effect (Effect)
import Effect.Aff (launchAff_)
import Effect.Class.Console (log)
import Yoga.Om as Om
import Yoga.Om.Layer (OmLayer, Scope, makeLayer, makeScopedLayer, provide, withScoped)

type Config = { url :: String }
type Database = { query :: String -> Array String }

main :: Effect Unit
main = launchAff_ do
  withScoped (databaseLayer `provide` configLayer) \{ database } ->
    log (show (database.query "select * from orders"))

configLayer :: OmLayer (scope :: Scope) () { config :: Config }
configLayer = makeLayer do
  pure { config: { url: "postgres://localhost/shop" } }

databaseLayer :: OmLayer (scope :: Scope, config :: Config) () { database :: Database }
databaseLayer = makeScopedLayer connect disconnect
  where
  connect = do
    { config } <- Om.ask
    log ("connecting to " <> config.url)
    pure { database: { query: \sql -> [ "a row for " <> sql ] } }
  disconnect _ = log "disconnected"
