-- | A yoga-sql-types query in yoga-go-http-om's OmIO. CI has no Postgres, so the pool points at
-- | a port nothing listens on and the query throws.
module Verify.YogaPostgresOmIO where

import Prelude

import Data.Either (Either, isLeft)
import Effect (Effect)
import Go.IO (launchIO_, try)
import Go.IO.Console (log)
import Yoga.Go.HTTP.OmIO (runOmIO)
import Yoga.Postgres as PG
import Yoga.Postgres.IO as PGIO
import Yoga.Postgres.TypedQueryOmIO (executeSql)
import Yoga.SQL.PostgresTypes (SQLQuery, int, sql, (^))

lowOn :: SQLQuery (below :: Int)
lowOn = sql $ "SELECT name FROM fruit WHERE stock < " ^ int @"below"

main :: Effect Unit
main = launchIO_ do
  postgresConnection <- PGIO.postgres { connection: PG.ConnectionString "postgres://postgres@127.0.0.1:1/shop" }
  outcome <- try (runOmIO { postgresConnection } (executeSql @_ @{ name :: String } lowOn { below: 5 }))
  log ("query failed: " <> show (isLeft (outcome :: Either _ (Either _ (Array { name :: String })))))
  PGIO.end postgresConnection
