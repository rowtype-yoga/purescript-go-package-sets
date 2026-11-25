module Verify.GoExec where

import Prelude

import Data.Either (Either(..))
import Effect (Effect)
import Effect.Console (log)
import Go.OS (Arg(..))
import Go.OS.Exec (ExecError(..), Program(..), command, run)

main :: Effect Unit
main = do
  echoed <- run (command (Program "echo") [ Arg "from", Arg "a child" ])
  case echoed of
    Left failure -> log ("echo failed: " <> show failure)
    Right output -> log ("echo said: " <> show output.stdout <> ", exit code " <> show output.exitCode)
  missing <- run (command (Program "no-such-program-verify") [])
  case missing of
    Left (ProgramNotFound program) -> log ("not found: " <> show program)
    Left failure -> log ("failed otherwise: " <> show failure)
    Right _ -> log "a program that shouldn't exist ran"
