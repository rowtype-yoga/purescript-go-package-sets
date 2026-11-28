-- | Checks that the package set works on Go. In a fresh project that uses nothing but the set:
-- |
-- | - every registry package in it compiles (`googoo build`),
-- | - every package in `verify/` compiles to Go, runs, and prints exactly its `expected.txt`,
-- | - and each package that comes from git has such a check.
-- |
-- |   gogogo scripts/verify.purs [package set]
-- |
-- | Run it from the repository's root. The set is `packages.json` unless you name another file or
-- | a URL, such as a tag's raw URL. `IRIS` picks the googoo binary (`googoo` on the PATH by
-- | default). CI runs the same module with `googoo run -p verify-runner`.
module Verify where

import Prelude

import Control.Alt ((<|>))
import Control.Parallel (parallel, sequential)
import Data.Array as Array
import Data.Either (Either(..), either)
import Data.Foldable (for_)
import Data.Maybe (Maybe(..), fromMaybe, isJust, maybe)
import Data.Newtype (un)
import Data.String (Pattern(..))
import Data.String as String
import Data.Time.Duration (Milliseconds(..))
import Data.Traversable (for)
import Data.Tuple (fst)
import Data.Tuple.Nested (type (/\), (/\))
import Effect (Effect)
import Effect.Aff (Aff, delay, launchAff_)
import Effect.Class (liftEffect)
import Effect.Console (log)
import Foreign (Foreign)
import Foreign.Object as Object
import Go.FilePath (FilePath(..))
import Go.OS (Arg(..), EnvName(..), EnvValue(..), ExitCode(..))
import Go.OS as OS
import Go.OS.Exec (Program(..), command)
import Go.OS.Exec as Exec
import Go.Path.Filepath as Filepath
import Yoga.JSON as JSON

main :: Effect Unit
main = launchAff_ do
  address <- packageSetAddress
  set <- readPackageSet (listedIn address)
  iris <- irisProgram
  warnAboutALocalRuntime
  checks <- checksIn (FilePath "verify")
  workspace <- freshWorkspace address set
  log ("Checking " <> describeAddress address <> " in " <> un FilePath workspace) # liftEffect
  registry <- registryPackagesCompile iris workspace set
  smokes <- for checks (runCheck iris workspace)
  let unchecked = set.fromGit # Array.filter (_ `Array.notElem` map _.name checks)
  report (Array.cons registry smokes) unchecked
  OS.removeAll workspace # liftEffect # void

-- | What the package set holds, split by where a package comes from.
type PackageSet = { fromRegistry :: Array String, fromGit :: Array String }

-- | Where the fresh project takes the set from.
data SetAddress = SetPath FilePath | SetURL String

-- | Which file says what the set holds: a URL is checked against this checkout's `packages.json`.
listedIn :: SetAddress -> FilePath
listedIn = case _ of
  SetPath path -> path
  SetURL _ -> FilePath "packages.json"

-- | A package in `verify/` whose program must print its `expected.txt`.
type Check = { name :: String, directory :: FilePath, expected :: String }

type Outcome = { label :: String, failure :: Maybe String }

readPackageSet :: FilePath -> Aff PackageSet
readPackageSet file = do
  text <- OS.readFile file # liftEffect >>= orDie ("can't read " <> un FilePath file)
  parsed :: { packages :: Object.Object Foreign } <- JSON.readJSON_ text # maybe (die (un FilePath file <> " isn't a package set")) pure
  let entries = Object.toUnfoldable parsed.packages :: Array (String /\ Foreign)
  pure
    { fromRegistry: entries # Array.filter isVersion # map fst
    , fromGit: entries # Array.filter (not <<< isVersion) # map fst
    }
  where
  isVersion (_ /\ entry) = isJust (JSON.read_ entry :: Maybe String)

-- | The first argument, or `packages.json` in the working directory.
packageSetAddress :: Aff SetAddress
packageSetAddress = do
  arguments <- OS.args # liftEffect
  case Array.head arguments <#> un Arg of
    Just url | String.contains (Pattern "://") url -> pure (SetURL url)
    given -> do
      absolute <- Filepath.abs (FilePath (fromMaybe "packages.json" given)) # liftEffect
      absolute # either (die <<< show) (pure <<< SetPath)

irisProgram :: Aff Program
irisProgram = do
  chosen <- OS.lookupEnv (EnvName "IRIS") # liftEffect
  pure (Program (maybe "googoo" (un EnvValue) chosen))

-- | A set is meant for the released Iris and its Go runtime, not a local iris-go checkout.
warnAboutALocalRuntime :: Aff Unit
warnAboutALocalRuntime = do
  local <- OS.lookupEnv (EnvName "IRIS_GO") # liftEffect
  for_ local \(EnvValue path) ->
    log ("Note: IRIS_GO=" <> path <> " builds against that iris-go checkout, not the released runtime.") # liftEffect

-- | Every directory in `verify/` with an `expected.txt`.
checksIn :: FilePath -> Aff (Array Check)
checksIn folder = do
  entries <- OS.readDir folder # liftEffect >>= orDie "can't list verify/"
  found <- for (entries # Array.filter OS.entryIsDir) \entry -> do
    let directory = Filepath.join [ folder, OS.entryName entry ]
    expected <- OS.readFile (Filepath.join [ directory, FilePath "expected.txt" ]) # liftEffect
    pure (expected # either (const Nothing) \text -> Just { name: un FilePath (OS.entryName entry), directory, expected: text })
  pure (Array.catMaybes found)

-- | A temporary workspace with a copy of `verify/`, a package that depends on every registry
-- | package, and the set as its only source of packages.
freshWorkspace :: SetAddress -> PackageSet -> Aff FilePath
freshWorkspace address set = do
  temporary <- OS.tempDir # liftEffect
  workspace <- OS.mkdirTemp temporary "go-package-set-" # liftEffect >>= orDie "can't make a temporary directory"
  _ <- runIn (FilePath ".") (Program "cp") [ "-R", "verify", un FilePath workspace ] >>= orDie "can't copy verify/"
  writeIn workspace "spago.yaml" (workspaceManifest address)
  writeIn workspace "everything/spago.yaml" (everythingManifest set.fromRegistry)
  writeIn workspace "everything/src/Verify/Everything.purs" everythingModule
  pure workspace

workspaceManifest :: SetAddress -> String
workspaceManifest address = String.joinWith "\n"
  [ "workspace:"
  , "  packageSet:"
  , case address of
      SetPath (FilePath path) -> "    path: " <> path
      SetURL url -> "    url: " <> url
  , ""
  ]

everythingManifest :: Array String -> String
everythingManifest packages = String.joinWith "\n" $
  [ "package:", "  name: verify-everything", "  dependencies:" ]
    <> map ("    - " <> _) packages
    <> [ "" ]

everythingModule :: String
everythingModule = String.joinWith "\n"
  [ "module Verify.Everything where"
  , ""
  , "import Prelude"
  , ""
  , "import Effect (Effect)"
  , ""
  , "main :: Effect Unit"
  , "main = pure unit"
  , ""
  ]

-- | `googoo build` of the package that depends on every registry package: they resolve together and
-- | each one compiles.
registryPackagesCompile :: Program -> FilePath -> PackageSet -> Aff Outcome
registryPackagesCompile iris workspace set = do
  log ("Compiling the " <> show (Array.length set.fromRegistry) <> " registry packages") # liftEffect
  built <- runIn workspace iris [ "build", "--js", "--quiet", "-p", "verify-everything" ]
  pure { label: "registry packages compile", failure: either Just (const Nothing) built }

-- | Compiles the check's package to Go, runs it and compares what it prints.
runCheck :: Program -> FilePath -> Check -> Aff Outcome
runCheck iris workspace check = do
  log ("Checking " <> check.name <> " on Go") # liftEffect
  built <- runIn workspace iris [ "go", "-p", "verify-" <> check.name ]
  failure <- case built of
    Left failure -> pure (Just failure)
    Right printed -> do
      ran <- runWithin (Milliseconds 60000.0) (FilePath (lastLine printed))
      pure case ran of
        Left failure -> Just failure
        Right output
          | output == check.expected -> Nothing
          | otherwise -> Just ("printed:\n" <> output <> "\nexpected:\n" <> check.expected)
  pure { label: check.name <> " on Go", failure }
  where
  lastLine printed = printed # String.trim # String.split (Pattern "\n") # Array.last # fromMaybe ""

report :: Array Outcome -> Array String -> Aff Unit
report outcomes unchecked = do
  for_ outcomes \{ label, failure } -> case failure of
    Nothing -> log ("ok    " <> label) # liftEffect
    Just reason -> log ("FAIL  " <> label <> "\n" <> indent reason) # liftEffect
  for_ unchecked \name ->
    log ("FAIL  " <> name <> " comes from git but has no verify/" <> name <> "/expected.txt") # liftEffect
  let failed = Array.length (Array.filter (isJust <<< _.failure) outcomes) + Array.length unchecked
  if failed == 0 then log "Every check passed." # liftEffect
  else do
    log (show failed <> " failed.") # liftEffect
    OS.exit (ExitCode 1) # liftEffect
  where
  indent text = text # String.split (Pattern "\n") # map ("      " <> _) # String.joinWith "\n"

-- | Runs the program in the directory: its standard output, or what went wrong.
runIn :: FilePath -> Program -> Array String -> Aff (Either String String)
runIn directory program arguments = do
  ran <- Exec.runAff ((command program (map Arg arguments)) { dir = Just directory })
  pure case ran of
    Left failure -> Left (show failure)
    Right output
      | output.exitCode == ExitCode 0 -> Right output.stdout
      | otherwise -> Left (lastLines 40 (output.stderr <> output.stdout))

-- | Runs the binary, and kills it if it's still going after the limit.
runWithin :: Milliseconds -> FilePath -> Aff (Either String String)
runWithin limit (FilePath binary) = do
  started <- Exec.start (command (Program binary) []) # liftEffect
  case started of
    Left failure -> pure (Left (show failure))
    Right process -> do
      finished <- sequential (parallel (Just <$> Exec.wait process) <|> parallel (Nothing <$ delay limit))
      case finished of
        Nothing -> do
          _ <- Exec.kill process # liftEffect
          pure (Left ("still running after " <> show limit))
        Just (Left failure) -> pure (Left (show failure))
        Just (Right output)
          | output.exitCode == ExitCode 0 -> pure (Right output.stdout)
          | otherwise -> pure (Left ("exit code " <> show output.exitCode <> "\n" <> lastLines 40 (output.stderr <> output.stdout)))

writeIn :: FilePath -> String -> String -> Aff Unit
writeIn directory relative text = do
  let file = Filepath.join [ directory, FilePath relative ]
  _ <- OS.mkdirAll (Filepath.dir file) # liftEffect >>= orDie ("can't make the folder of " <> relative)
  OS.writeFile file text # liftEffect >>= orDie ("can't write " <> relative)

lastLines :: Int -> String -> String
lastLines count text = text # String.trim # String.split (Pattern "\n") # Array.takeEnd count # String.joinWith "\n"

describeAddress :: SetAddress -> String
describeAddress = case _ of
  SetPath (FilePath path) -> path
  SetURL url -> url

orDie :: forall error a. Show error => String -> Either error a -> Aff a
orDie context = either (\failure -> die (context <> ": " <> show failure)) pure

die :: forall a. String -> Aff a
die message = do
  log message # liftEffect
  OS.exit (ExitCode 1) # liftEffect
