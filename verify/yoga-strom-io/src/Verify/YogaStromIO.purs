module Verify.YogaStromIO where

import Prelude

import Data.Either (Either(..))
import Effect (Effect)
import Go.IO (launchIO_)
import Go.IO.Console (log)
import Yoga.Go.HTTP.OmIO (OmIO, runOmIO)
import Yoga.OmIO.Strom as Strom

main :: Effect Unit
main = launchIO_ do
  collected <- runOmIO unit firstThreeEvenNumbers
  case collected of
    Left _ -> log "the stream failed"
    Right numbers -> log ("first three even numbers: " <> show numbers)
  summed <- runOmIO unit oneToAHundredSummed
  case summed of
    Left _ -> log "the fold failed"
    Right total -> log ("1 to 100 summed: " <> show total)

firstThreeEvenNumbers :: OmIO Unit () (Array Int)
firstThreeEvenNumbers = Strom.range 1 1000000 # map (_ * 2) # Strom.take 3 # Strom.runCollect

oneToAHundredSummed :: OmIO Unit () Int
oneToAHundredSummed = Strom.range 1 101 # Strom.runFold 0 (+)
