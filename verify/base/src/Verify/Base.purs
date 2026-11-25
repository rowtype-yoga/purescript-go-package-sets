-- | The registry part of the set, compiled to Go: one line per package family, each printing
-- | what it computed. `expected.txt` is what JavaScript prints for the same program.
module Verify.Base where

import Prelude

import Control.Monad.ST as ST
import Control.Monad.ST.Ref as STRef
import Control.Monad.State (execState, modify_)
import Data.Array as Array
import Data.Foldable (for_)
import Data.HashMap as HashMap
import Data.Int (hexadecimal, toStringAs)
import Data.Int64 as Int64
import Data.Lazy (defer, force)
import Data.List as List
import Data.Map as Map
import Data.Maybe (Maybe(..))
import Data.Number (floor)
import Data.String (Pattern(..))
import Data.String as String
import Data.Time.Duration (Minutes(..), Seconds, convertDuration)
import Data.Tuple.Nested ((/\))
import Data.Variant (Variant, inj, match)
import Effect (Effect)
import Effect.Aff (forkAff, joinFiber, launchAff_)
import Effect.Aff.AVar as AVar
import Effect.Class (liftEffect)
import Effect.Console (log)
import Effect.Ref as Ref
import Foreign.Object as Object
import Record as Record
import Type.Proxy (Proxy(..))
import Yoga.JSON as JSON

main :: Effect Unit
main = do
  log $ "arrays: " <> show doubledAboveTen
  log $ "strings: " <> wordsJoined
  log $ "integers: " <> toStringAs hexadecimal 255
  log $ "numbers: " <> show (floor 2.7)
  log $ "ordered-collections: " <> show (Map.lookup 2 numberNames)
  log $ "unordered-collections: " <> show (HashMap.lookup "go" languageAges)
  log $ "foreign-object: " <> show (Object.keys (Object.fromHomogeneous { purescript: 1, go: 2 }))
  log $ "lists: " <> show (List.sort (List.fromFoldable [ 3, 1, 2 ]))
  log $ "st: " <> show sumToHundred
  log $ "transformers: " <> show (execState (for_ [ 1, 2, 3 ] \n -> modify_ (_ + n)) 0)
  log $ "variant: " <> describe (inj (Proxy :: _ "count") 3)
  log $ "record: " <> show (Record.merge { language: "PureScript" } { backend: "Go" })
  log $ "lazy: " <> show (force (defer \_ -> 6 * 7))
  log $ "int64: " <> Int64.toString (Int64.fromInt 2147483647 + Int64.fromInt 1)
  log $ "datetime: " <> show (convertDuration (Minutes 1.5) :: Seconds)
  log $ "yoga-json: " <> show (JSON.readJSON_ (JSON.writeJSON { name: "Ada", langs: [ "purs", "go" ] }) :: Maybe { name :: String, langs :: Array String })
  counter <- Ref.new 0
  for_ [ 1, 2, 3 ] \_ -> Ref.modify_ (_ + 1) counter
  counted <- Ref.read counter
  log $ "refs: " <> show counted
  launchAff_ do
    box <- AVar.empty
    writer <- forkAff (AVar.put "handed over" box)
    received <- AVar.take box
    joinFiber writer
    log ("aff and avar: " <> received) # liftEffect
  where
  doubledAboveTen = Array.range 1 10 # map (_ * 2) # Array.filter (_ > 10)
  wordsJoined = String.split (Pattern " ") "go purescript go" # Array.nub # String.joinWith ", "
  numberNames = Map.fromFoldable [ 1 /\ "one", 2 /\ "two" ]
  languageAges = HashMap.fromArray [ "go" /\ 2009, "purescript" /\ 2013 ]
  sumToHundred = ST.run do
    total <- STRef.new 0
    ST.for 1 101 \n -> STRef.modify (_ + n) total
    STRef.read total
  describe :: Variant (count :: Int, name :: String) -> String
  describe = match { count: \n -> "count " <> show n, name: \n -> "name " <> n }
