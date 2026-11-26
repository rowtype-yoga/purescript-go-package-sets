module Verify.GoSpec where

import Prelude

import Effect (Effect)
import Effect.Class (liftEffect)
import Effect.Console (log)
import Test.Spec (describe, it)
import Test.Spec.Assertions (shouldEqual)
import Test.Spec.Runner.Go (runSpecAndExitProcess)

main :: Effect Unit
main = runSpecAndExitProcess [] do
  describe "go-spec" do
    it "runs a spec on Go and exits with 0" do
      (1 + 1) `shouldEqual` 2
      log "a spec ran on Go" # liftEffect
