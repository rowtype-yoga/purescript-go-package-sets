module Verify.Harmonica where

import Prelude

import Data.Int (round)
import Effect (Effect)
import Go.IO (launchIO_)
import Go.IO.Console (log)
import Harmonica as Harmonica

main :: Effect Unit
main = launchIO_ do
  log ("a spring from 0 to 100 after 30 frames: " <> show (round settled.position))
  where
  bouncy = Harmonica.spring { fps: 60, frequency: 7.0, damping: 0.6 }
  settled = go 30 { position: 0.0, velocity: 0.0 }
  go frames motion
    | frames == 0 = motion
    | otherwise = go (frames - 1) (Harmonica.step bouncy 100.0 motion)
