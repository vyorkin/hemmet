{-# LANGUAGE ExistentialQuantification #-}
{-# LANGUAGE KindSignatures #-}

module Hemmet.App.Cli where

import Data.Maybe
import Data.Monoid
import Options.Applicative

import Hemmet hiding (Parser)

data Input
    = Expression String
    | Examples
    | StdIn

data Options :: * -> * where
    Options :: forall a e. e -> Runner a -> Backend a -> Options e

cliWith :: Parser a -> ParserInfo (Options a)
cliWith extra =
    info
        (commands extra <**> helper)
        (progDesc "Expands the snippets" <>
         header "Hemmet, the snippet expander" <>
         fullDesc)

commands :: Parser a -> Parser (Options a)
commands extra = subparser $ bemC <> ftreeC
  where
    bemC = cmd "bem" (bem <&> argBemRunner extra) "Generates BEM markup"
    ftreeC =
        cmd
            "ftree"
            (fileTree <&> argFileTreeRunner extra)
            "Generates the file trees"

argBemRunner :: Parser a -> Parser (BemBackend -> Options a)
argBemRunner extra = subparser $ flux <> html <> css
  where
    inner = fmap Options extra
    flux = cmd "react-flux" (bemReactFlux <&> inner) "Generates react-flux code"
    html = cmd "html" (bemHtml <&> inner) "Generates HTML"
    css = cmd "css" (bemCss <&> inner) "Generates CSS"

argFileTreeRunner :: Parser a -> Parser (FileTreeBackend -> Options a)
argFileTreeRunner extra = subparser $ tree <> bash
  where
    inner = fmap Options extra
    tree = cmd "tree" (treeLike <&> inner) "Generates GNU Tree-like output"
    bash = cmd "bash" (bashScript <&> inner) "Generates Bash-script"

optInput :: Parser Input
optInput = fromMaybe StdIn <$> (optional example <|> optional expression)
  where
    example = flag' Examples (long "examples" <> help "Show some examples")
    expression =
        Expression <$>
        strOption
            (short 'e' <> long "expression" <> metavar "EXPRESSION" <>
             help "Expression (snippet) to expand")

cmd :: String -> Parser a -> String -> Mod CommandFields a
cmd c p desc = command c $ info (p <**> helper) $ progDesc desc

(<&>) :: Functor f => a -> f (a -> b) -> f b
x <&> f = ($ x) <$> f
