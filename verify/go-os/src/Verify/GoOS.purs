module Verify.GoOS where

import Prelude

import Data.Either (Either(..))
import Effect (Effect)
import Effect.Console (log)
import Go.FilePath (FilePath(..))
import Go.OS (EnvName(..), EnvValue(..))
import Go.OS as OS
import Go.Path.Filepath as Filepath

main :: Effect Unit
main = do
  log $ "base and extension: " <> show (Filepath.base notes) <> " " <> show (Filepath.ext notes)
  OS.setenv (EnvName "VERIFY_GO_OS") (EnvValue "set")
  log <<< ("environment: " <> _) <<< show =<< OS.lookupEnv (EnvName "VERIFY_GO_OS")
  temporary <- OS.tempDir
  folder <- OS.mkdirTemp temporary "verify-go-os-"
  case folder of
    Left failure -> log ("mkdirTemp failed: " <> show failure)
    Right directory -> writeAndReadBack directory
  where
  notes = Filepath.join [ FilePath "some", FilePath "notes.txt" ]

writeAndReadBack :: FilePath -> Effect Unit
writeAndReadBack directory = do
  _ <- OS.writeFile file "written by Go"
  log <<< ("read back: " <> _) <<< show =<< OS.readFile file
  _ <- OS.removeAll directory
  log <<< ("gone: " <> _) <<< show <<< not =<< OS.exists directory
  where
  file = Filepath.join [ directory, FilePath "notes.txt" ]
