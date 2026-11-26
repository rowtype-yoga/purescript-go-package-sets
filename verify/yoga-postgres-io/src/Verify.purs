-- | A typed query program on IO. CI has no Postgres, so the pool points at a port nothing
-- | listens on and every statement fails.
module Verify.YogaPostgresIO where

import Prelude

import Data.Either (Either, isLeft)
import Effect (Effect)
import Go.IO (launchIO_, try)
import Go.IO.Console (log)
import Yoga.Postgres as PG
import Yoga.Postgres.IO as PGIO
import Yoga.Postgres.TypedQuery.IO (executeSql)
import Yoga.SQL.PostgresTypes (SQLQuery, int, sql, (^))

type Fruit = { name :: String, stock :: Int }

lowOn :: SQLQuery (below :: Int)
lowOn = sql $ "SELECT name, stock FROM fruit WHERE stock < " ^ int @"below"

main :: Effect Unit
main = launchIO_ do
  conn <- PGIO.postgres { connection: PG.ConnectionString "postgres://postgres@127.0.0.1:1/shop" }
  PGIO.ping conn >>= \healthy -> log ("ping: " <> show healthy)
  low <- try (executeSql @_ @Fruit lowOn { below: 5 } conn)
  log ("query failed: " <> show (isLeft (low :: Either _ (Either String (Array Fruit)))))
  PGIO.end conn
