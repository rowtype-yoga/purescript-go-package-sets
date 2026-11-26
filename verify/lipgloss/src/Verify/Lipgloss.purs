module Verify.Lipgloss where

import Prelude

import Effect (Effect)
import Go.IO (launchIO_)
import Go.IO.Console (log)
import Lipgloss as L

main :: Effect Unit
main = launchIO_ do
  log (L.joinHorizontal L.top [ card "Lip Gloss", card "on Go" ])
  where
  card = L.render (L.newStyle # L.border L.roundedBorder # L.padding 0 1 0 1)
