module Unison.Cli.TypeCheck
  ( typecheck,
    typecheckHelper,
    typecheckFile,
    typecheckTerm
  )
where

import Control.Monad.Reader (ask)
import qualified Data.Text as Text
import qualified Data.Map as Map
import qualified Unison.Builtin as Builtin
import Unison.Cli.Monad (Cli)
import qualified Unison.Cli.Monad as Cli
import Unison.Codebase (Codebase)
import qualified Unison.Codebase as Codebase
import Unison.FileParsers (parseAndSynthesizeFile, synthesizeFile')
import Unison.Names (Names)
import Unison.NamesWithHistory (NamesWithHistory (..))
import Unison.Parser.Ann (Ann (..))
import Unison.Prelude
import qualified Unison.Result as Result
import Unison.Symbol (Symbol(Symbol))
import qualified Unison.Syntax.Lexer as L
import qualified Unison.Syntax.Parser as Parser
import Unison.Type (Type)
import Unison.Term (Term)
import qualified Unison.Var as Var
import qualified Unison.UnisonFile as UF

typecheck ::
  [Type Symbol Ann] ->
  NamesWithHistory ->
  Text ->
  (Text, [L.Token L.Lexeme]) ->
  Cli
    ( Result.Result
        (Seq (Result.Note Symbol Ann))
        (Either (UF.UnisonFile Symbol Ann) (UF.TypecheckedUnisonFile Symbol Ann))
    )
typecheck ambient names sourceName source =
  Cli.time "typecheck" do
    Cli.Env {codebase, generateUniqueName} <- ask
    uniqueName <- liftIO generateUniqueName
    (liftIO . Result.getResult) $
      parseAndSynthesizeFile
        ambient
        (((<> Builtin.typeLookup) <$>) . Codebase.typeLookupForDependencies codebase)
        (Parser.ParsingEnv uniqueName names)
        (Text.unpack sourceName)
        (fst source)

typecheckHelper ::
  MonadIO m =>
  Codebase IO Symbol Ann ->
  IO Parser.UniqueName ->
  [Type Symbol Ann] ->
  NamesWithHistory ->
  Text ->
  (Text, [L.Token L.Lexeme]) ->
  m
    ( Result.Result
        (Seq (Result.Note Symbol Ann))
        (Either (UF.UnisonFile Symbol Ann) (UF.TypecheckedUnisonFile Symbol Ann))
    )
typecheckHelper codebase generateUniqueName ambient names sourceName source = do
  uniqueName <- liftIO generateUniqueName
  (liftIO . Result.getResult) $
    parseAndSynthesizeFile
      ambient
      (((<> Builtin.typeLookup) <$>) . Codebase.typeLookupForDependencies codebase)
      (Parser.ParsingEnv uniqueName names)
      (Text.unpack sourceName)
      (fst source)

typecheckTerm ::
  Term Symbol Ann ->
  Cli
    ( Result.Result
        (Seq (Result.Note Symbol Ann))
        (Type Symbol Ann))
typecheckTerm tm = do
  Cli.Env { generateUniqueName } <- ask
  un <- liftIO generateUniqueName
  let v = Symbol 0 (Var.Inference Var.Other)
  fmap extract <$>
    typecheckFile' [] (UF.UnisonFileId mempty mempty [(v, tm)] mempty)
  where
    extract tuf
      | [[(_,_,ty)]] <- UF.topLevelComponents' tuf = ty
      | otherwise = error "internal error: typecheckTerm"

typecheckFile' ::
  [Type Symbol Ann] ->
  UF.UnisonFile Symbol Ann ->
  Cli
    ( Result.Result
        (Seq (Result.Note Symbol Ann))
        (UF.TypecheckedUnisonFile Symbol Ann))
typecheckFile' ambient file = do
  Cli.Env {codebase} <- ask
  typeLookup <-
    liftIO $
      (<> Builtin.typeLookup)
        <$> Codebase.typeLookupForDependencies codebase (UF.dependencies file)
  pure $ synthesizeFile' ambient typeLookup file

typecheckFile ::
  [Type Symbol Ann] ->
  UF.UnisonFile Symbol Ann ->
  Cli
    ( Result.Result
        (Seq (Result.Note Symbol Ann))
        (Either Names (UF.TypecheckedUnisonFile Symbol Ann))
    )
typecheckFile ambient file = fmap Right <$> typecheckFile' ambient file
