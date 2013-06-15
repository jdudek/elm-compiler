{-# LANGUAGE TypeSynonymInstances, FlexibleInstances #-}
{- | This module exports the functions necessary for compiling Elm code into the
     respective HTML, CSS, and JS code.

     The documentation for the Elm language is available at
     <http://elm-lang.org/Documentation.elm>, and many interactive examples are
     available at <http://elm-lang.org/Examples.elm>

     Example implementations using Yesod and Happstack are available
     at <https://github.com/tazjin/Elm/tree/master/Examples>
-}
module Language.Elm (compile, toHtml, moduleName, runtime, docs) where

import Data.List (intercalate)
import Data.Version (showVersion)
import Generate.JavaScript (showErr, jsModule)
import Generate.Html (generateHtml)
import Initialize (buildFromSource)
import Parse.Helpers
import Parse.Module (moduleDef)
import SourceSyntax.Module
import Text.Blaze.Html (Html)
import Text.Parsec (option,optional)
import Paths_Elm

-- |This function compiles Elm code to JavaScript. It will return either
--  an error message or the compiled JS code.
compile :: String -> Either String String
compile source = fmap jsModule modul
    where
      modul :: Either String (Module () String)
      modul = buildFromSource False source

-- |This function extracts the module name of a given source program.
moduleName :: String -> Maybe String
moduleName source = case iParse getModuleName "" source of
                      Right name -> Just name
                      Left _     -> Nothing
    where
      getModuleName = do
        optional freshLine
        (names, _) <- moduleDef
        return (intercalate "." names)

-- |This function compiles Elm code into a full HTML page.
toHtml :: String -- ^ Location of elm-min.js as expected by the browser
       -> String -- ^ The page title
       -> String -- ^ The elm source code
       -> Html
toHtml = generateHtml

-- |The absolute path to Elm's runtime system.
runtime :: IO FilePath
runtime = getDataFileName "elm-runtime.js"

-- |The absolute path to Elm's core library documentation.
docs :: IO FilePath
docs = getDataFileName "docs.json"
