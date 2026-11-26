module Verify.Glamour where

import Prelude

import Data.Array as Array
import Data.Either (Either(..))
import Data.String (Pattern(..))
import Data.String as String
import Effect (Effect)
import Glamour (Theme(..))
import Glamour as Glamour
import Go.IO (launchIO_)
import Go.IO.Console (log)

main :: Effect Unit
main = launchIO_ do
  case Glamour.render _ { theme = Ascii, width = 40 } "# Glamour\n\non *Go*" of
    Right styled -> log (withoutPadding styled)
    Left problem -> log ("can't render: " <> problem)
  where
  withoutPadding styled = styled
    # String.split (Pattern "\n")
    <#> String.trim
    # Array.filter (_ /= "")
    # String.joinWith "\n"
