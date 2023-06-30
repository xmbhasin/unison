{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE DerivingVia #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}

module Unison.Test.Ucm
  ( initCodebase,
    deleteCodebase,
    runTranscript,
    lowLevel,
    CodebaseFormat (..),
    Transcript,
    unTranscript,
    Codebase (..),
  )
where

import Control.Monad (when)
import Data.Text qualified as Text
import System.Directory (removeDirectoryRecursive)
import System.IO.Temp qualified as Temp
import U.Util.Text (stripMargin)
import Unison.Codebase (CodebasePath)
import Unison.Codebase qualified as Codebase
import Unison.Codebase.Init qualified as Codebase.Init
import Unison.Codebase.Init.CreateCodebaseError (CreateCodebaseError (..))
import Unison.Codebase.SqliteCodebase qualified as SC
import Unison.Codebase.TranscriptParser qualified as TR
import Unison.Parser.Ann (Ann)
import Unison.Prelude (traceM)
import Unison.PrettyTerminal qualified as PT
import Unison.Symbol (Symbol)
import Unison.Util.Pretty qualified as P

data CodebaseFormat = CodebaseFormat2 deriving (Show, Enum, Bounded)

data Codebase = Codebase CodebasePath CodebaseFormat deriving (Show)

-- newtype Transcript = Transcript {unTranscript :: Text}
--   deriving (IsString, Show, Semigroup) via Text
type Transcript = String

unTranscript :: a -> a
unTranscript = id

type TranscriptOutput = String

debugTranscriptOutput :: Bool
debugTranscriptOutput = False

initCodebase :: CodebaseFormat -> IO Codebase
initCodebase fmt = do
  let cbInit = case fmt of CodebaseFormat2 -> SC.init
  tmp <-
    Temp.getCanonicalTemporaryDirectory
      >>= flip Temp.createTempDirectory "ucm-test"
  result <- Codebase.Init.withCreatedCodebase cbInit "ucm-test" tmp SC.DoLock (const $ pure ())
  case result of
    Left CreateCodebaseAlreadyExists -> fail $ P.toANSI 80 "Codebase already exists"
    Right _ -> pure $ Codebase tmp fmt

deleteCodebase :: Codebase -> IO ()
deleteCodebase (Codebase path _) = removeDirectoryRecursive path

runTranscript :: Codebase -> Transcript -> IO TranscriptOutput
runTranscript (Codebase codebasePath fmt) transcript = do
  let err e = fail $ "Parse error: \n" <> show e
      cbInit = case fmt of CodebaseFormat2 -> SC.init
  TR.withTranscriptRunner "Unison.Test.Ucm.runTranscript Invalid Version String" configFile $ \runner -> do
    result <- Codebase.Init.withOpenCodebase cbInit "transcript" codebasePath SC.DoLock SC.DontMigrate \codebase -> do
      Codebase.runTransaction codebase (Codebase.installUcmDependencies codebase)
      let transcriptSrc = stripMargin . Text.pack $ unTranscript transcript
      output <- either err Text.unpack <$> runner "transcript" transcriptSrc (codebasePath, codebase)
      when debugTranscriptOutput $ traceM output
      pure output
    case result of
      Left e -> fail $ P.toANSI 80 (P.shown e)
      Right x -> pure x
  where
    configFile = Nothing

lowLevel :: Codebase -> (Codebase.Codebase IO Symbol Ann -> IO a) -> IO a
lowLevel (Codebase root fmt) action = do
  let cbInit = case fmt of CodebaseFormat2 -> SC.init
  result <- Codebase.Init.withOpenCodebase cbInit "lowLevel" root SC.DoLock SC.DontMigrate action
  case result of
    Left e -> PT.putPrettyLn (P.shown e) *> pure (error "This really should have loaded")
    Right a -> pure a
