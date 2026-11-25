module Verify.GoIO where

import Prelude

import Data.Traversable (for)
import Effect (Effect)
import Go.IO (IO, forkIO, launchIO_)
import Go.IO.Console (log)
import Go.IO.MVar (newEmptyMVar, putMVar, takeMVar)

main :: Effect Unit
main = launchIO_ do
  squares <- for [ 1, 2, 3, 4 ] (onItsOwnThread square)
  log ("squared on four threads: " <> show squares)
  where
  square n = pure (n * n)

-- | Runs the action on a new thread and waits for its answer.
onItsOwnThread :: forall a b. (a -> IO b) -> a -> IO b
onItsOwnThread action input = do
  answer <- newEmptyMVar
  _ <- forkIO (action input >>= putMVar answer)
  takeMVar answer
