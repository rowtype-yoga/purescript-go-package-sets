module Verify.YogaSqlTypes where

import Prelude

import Effect (Effect)
import Effect.Console (log)
import Yoga.JSON (unsafeStringify)
import Yoga.SQL.PostgresTypes (SQLQuery, argsFor, int, sql, sqlQueryToString, str, (^))

findUser :: SQLQuery (id :: Int, name :: String)
findUser = sql $ "SELECT id, name FROM users WHERE id = " ^ int @"id" ^ " AND name = " ^ str @"name"

main :: Effect Unit
main = do
  log (sqlQueryToString findUser)
  log (unsafeStringify (argsFor findUser { name: "Ada", id: 7 }))
