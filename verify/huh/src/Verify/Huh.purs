module Verify.Huh where

import Prelude

import Bubbletea as Tea
import Bubbletea.Hooks (Component, component, render)
import Bubbletea.Key (KeyCode(..), key)
import Bubbletea.Testing (Step(..))
import Bubbletea.Testing as Testing
import Data.Tuple.Nested ((/\))
import Effect (Effect)
import Go.IO (launchIO_)
import Go.IO.Console (log)
import Huh (Form, Status(..))
import Huh as Huh

main :: Effect Unit
main = launchIO_ do
  result <- Testing.runComponent [ Type "Ada", Press (key Enter), Press (key Down), Press (key Enter) ] order
  log result.frame

data Burger = Classic | Chickwich

order :: Component Unit Void
order = component \_ -> do
  form <- Huh.useForm burgerFor
  render do
    status <- form.status
    pure $ Tea.view case status of
      Done answer -> "a " <> name answer.burger <> " for " <> answer.who
      _ -> "not yet"
  where
  name = case _ of
    Classic -> "Charmburger Classic"
    Chickwich -> "Chickwich"

burgerFor :: Form { who :: String, burger :: Burger }
burgerFor = ado
  who <- Huh.input _ { title = "Name" }
  burger <- Huh.select _ { title = "Burger" } [ "Charmburger Classic" /\ Classic, "Chickwich" /\ Chickwich ]
  in { who, burger }
