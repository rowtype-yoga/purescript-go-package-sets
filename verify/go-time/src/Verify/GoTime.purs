module Verify.GoTime where

import Prelude

import Data.Either (Either(..))
import Effect (Effect)
import Effect.Console (log)
import Go.Time as Time

main :: Effect Unit
main = case Time.parse Time.rfc3339 "2026-11-25T10:30:00Z" of
  Left failure -> log ("parse failed: " <> show failure)
  Right instant -> do
    log ("date only: " <> Time.format Time.dateOnly instant)
    log ("time only: " <> Time.format Time.timeOnly instant)
