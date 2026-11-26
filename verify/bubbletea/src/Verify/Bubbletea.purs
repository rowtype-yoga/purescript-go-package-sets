module Verify.Bubbletea where

import Prelude

import Bubbletea (App, Cmd, Event(..))
import Bubbletea as Tea
import Bubbletea.Key (KeyCode(..), key)
import Bubbletea.Testing (Step(..))
import Bubbletea.Testing as Testing
import Data.Tuple.Nested (type (/\), (/\))
import Effect (Effect)
import Go.IO (launchIO_)
import Go.IO.Console (log)

main :: Effect Unit
main = launchIO_ do
  result <- Testing.run [ Press (key Up), Press (key Up), Press (key Up), Press (key Down), Type "q" ] counter
  log ("headless counter at " <> show result.model.count <> ", quit: " <> show result.quit)

counter :: App { count :: Int } Void
counter = { init: { count: 0 } /\ mempty, update, view }
  where
  update :: Event Void -> { count :: Int } -> { count :: Int } /\ Cmd Void
  update event model = case event of
    KeyPress { code: Char 'q' } -> model /\ Tea.quit
    KeyPress { code: Up } -> model { count = model.count + 1 } /\ mempty
    KeyPress { code: Down } -> model { count = model.count - 1 } /\ mempty
    _ -> model /\ mempty
  view model = Tea.view ("Counter: " <> show model.count)
