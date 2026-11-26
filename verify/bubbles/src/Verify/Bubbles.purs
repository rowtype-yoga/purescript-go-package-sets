module Verify.Bubbles where

import Prelude

import Bubbles.TextInput (TextInput)
import Bubbles.TextInput as TextInput
import Bubbletea (App, Event(..))
import Bubbletea as Tea
import Bubbletea.Key (KeyCode(..), key)
import Bubbletea.Testing (Step(..))
import Bubbletea.Testing as Testing
import Data.Tuple.Nested ((/\))
import Effect (Effect)
import Go.IO (launchIO_)
import Go.IO.Console (log)

main :: Effect Unit
main = launchIO_ do
  result <- Testing.run [ Type "Pikachu", Press (key Enter) ] pokémon
  log ("typed into a text input: " <> result.model.submitted)

type Model = { input :: TextInput, submitted :: String }

pokémon :: App Model Unit
pokémon = { init: { input: TextInput.new _ { focused = true }, submitted: "" } /\ mempty, update, view }
  where
  update event model = case event of
    KeyPress { code: Enter } -> model { submitted = TextInput.value model.input } /\ Tea.quit
    _ -> do
      let input /\ cmd = TextInput.update event model.input
      model { input = input } /\ cmd
  view model = Tea.view (TextInput.view model.input)
