module Verify.GoMap where

import Prelude

import Data.Foldable (for_)
import Data.Maybe (Maybe(..), fromMaybe)
import Effect (Effect)
import Effect.Console (log)
import Go.Map as GoMap

main :: Effect Unit
main = do
  tallies <- GoMap.new
  for_ [ "b", "a", "b", "c", "b" ] \word -> GoMap.alter countOneMore word tallies
  GoMap.delete "c" tallies
  entries <- GoMap.entries tallies
  log ("tallies: " <> show entries)
  where
  countOneMore count = Just (1 + fromMaybe 0 count)
