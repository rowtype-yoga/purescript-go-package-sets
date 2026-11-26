-- | An Om program on yoga-postgres-om. CI has no Postgres, so the pool points at a port nothing
-- | listens on and the query lands in the exception channel.
module Verify.YogaPostgresOm where

import Prelude

import Effect (Effect)
import Effect.Aff (launchAff_)
import Effect.Class (liftEffect)
import Effect.Class.Console (log)
import Yoga.Om as Om
import Yoga.Postgres as PG
import Yoga.Postgres.PostgresOm as Postgres

main :: Effect Unit
main = launchAff_ do
  postgresConnection <- PG.postgres { connection: PG.ConnectionString "postgres://postgres@127.0.0.1:1/shop" } # liftEffect
  answer <- Om.runOm { postgresConnection }
    { exception: \_ -> pure "the query failed with an exception"
    , parseError: \_ -> pure "the rows didn't parse"
    }
    (Postgres.query @{ n :: Int } (PG.SQL "SELECT 1 AS n") [] <#> show)
  log answer
  PG.end postgresConnection
