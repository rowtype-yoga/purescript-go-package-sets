-- | A message round trip through yoga-protobuf. The codec is what protoc-gen-purescript writes
-- | for `message HelloRequest { string name = 1; }`.
module Verify.YogaProtobuf where

import Prelude

import Data.Either (Either(..))
import Data.Function.Uncurried (mkFn3)
import Effect (Effect)
import Effect.Console (log)
import Yoga.Protobuf.Bytes (Bytes)
import Yoga.Protobuf.Bytes as Bytes
import Yoga.Protobuf.Decode (Reader, decodeMessage)
import Yoga.Protobuf.Error (DecodeError(..), failure)
import Yoga.Protobuf.Wire as Wire
import Yoga.Protobuf.Writer (Writer, encodeWith)
import Yoga.Protobuf.Writer as Writer

main :: Effect Unit
main = do
  log $ "encoded: " <> show (Bytes.toArray encoded)
  log $ "decoded: " <> show (decodeHelloRequest encoded)
  log $ "truncated decodes to a Left: " <> show (isLeft (decodeHelloRequest truncated))
  where
  encoded = encodeHelloRequest { name: "Go" }
  truncated = Bytes.fromArray [ 10, 5, 71 ]
  isLeft = case _ of
    Left _ -> true
    Right _ -> false

type HelloRequest = { name :: String }

decodeHelloRequest :: Bytes -> Either DecodeError HelloRequest
decodeHelloRequest input = decodeMessage readHelloRequest input

encodeHelloRequest :: HelloRequest -> Bytes
encodeHelloRequest message = encodeWith writeHelloRequest message

readHelloRequest :: Reader HelloRequest
readHelloRequest = mkFn3 \input start end -> do
  let
    loop position name
      | position >= end = Right { name }
      | otherwise = do
          let afterTag = Wire.varintEnd input position end
          if afterTag < 0 then Left (failure afterTag position)
          else case Wire.varint32 input position of
            10 -> do
              let payload = Wire.varintEnd input afterTag end
              let next = Wire.delimitedEnd input afterTag payload end
              if next < 0 then Left (failure next afterTag)
              else do
                let text = Wire.string input payload next
                if text == Wire.invalidUtf8 then Left (InvalidUtf8 payload)
                else loop next text
            tag -> do
              let next = Wire.skip input tag afterTag end
              if next < 0 then Left (failure next afterTag)
              else loop next name
  loop start ""

writeHelloRequest :: Writer -> HelloRequest -> Effect Unit
writeHelloRequest writer message = do
  when (message.name /= "") do
    Writer.string writer message.name
    Writer.tag writer 10
