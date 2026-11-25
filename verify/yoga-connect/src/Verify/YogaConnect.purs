module Verify.YogaConnect where

import Prelude

import Demo.Proto.Greeter.V1.Greeter (greeter)
import Effect (Effect)
import Effect.Console (log)
import Yoga.Connect.Service (serviceName)
import Yoga.Connect.Status (Code(..), codeName, codeNumber)

main :: Effect Unit
main = do
  log ("service: " <> serviceName greeter)
  log ("NotFound is gRPC code " <> show (codeNumber NotFound) <> ", " <> codeName NotFound)
