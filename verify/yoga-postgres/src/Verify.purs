-- | A typed query program, compiled and linked against pgx. CI has no Postgres, so the pool
-- | points at a port nothing listens on and every statement fails.
module Verify.YogaPostgres where

import Prelude

import Data.Either (Either, isLeft)
import Effect (Effect)
import Effect.Aff (launchAff_, try)
import Effect.Class (liftEffect)
import Effect.Class.Console (log)
import Type.Function (type (#))
import Yoga.Postgres as PG
import Yoga.Postgres.Schema as Schema
import Yoga.Postgres.TypedQuery (executeSql)
import Yoga.SQL.PostgresTypes (SQLQuery, int, sql, sqlQueryToString, (^))

type FruitTable = Schema.Table "fruit" (name :: String # Schema.PrimaryKey, stock :: Int)

type Fruit = { name :: String, stock :: Int }

lowOn :: SQLQuery (below :: Int)
lowOn = sql $ "SELECT name, stock FROM fruit WHERE stock < " ^ int @"below"

main :: Effect Unit
main = launchAff_ do
  log (Schema.createTableDDL @FruitTable)
  log (sqlQueryToString lowOn)
  conn <- PG.postgres { connection: PG.ConnectionString "postgres://postgres@127.0.0.1:1/shop" } # liftEffect
  PG.options conn # liftEffect >>= show >>> log
  PG.ping conn >>= \healthy -> log ("ping: " <> show healthy)
  low <- try (executeSql @_ @Fruit lowOn { below: 5 } conn)
  log ("query failed: " <> show (isLeft (low :: Either _ (Either String (Array Fruit)))))
  PG.end conn
