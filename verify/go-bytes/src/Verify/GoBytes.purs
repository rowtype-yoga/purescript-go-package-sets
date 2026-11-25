module Verify.GoBytes where

import Prelude

import Effect (Effect)
import Effect.Console (log)
import Go.Bytes (ByteCount(..))
import Go.Bytes as Bytes

main :: Effect Unit
main = do
  log $ "utf-8 bytes: " <> show (Bytes.toArray greeting)
  log $ "size: " <> show (Bytes.size greeting)
  log $ "first three bytes: " <> Bytes.toString (Bytes.slice (ByteCount 0.0) (ByteCount 3.0) greeting)
  where
  greeting = Bytes.fromString "héllo"
