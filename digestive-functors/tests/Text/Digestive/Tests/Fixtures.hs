{-# LANGUAGE OverloadedStrings #-}
module Text.Digestive.Tests.Fixtures
    ( TrainerM
    , runTrainerM
    , Type (..)
    , Pokemon (..)
    , pokemonForm
    , Ball (..)
    , ballForm
    , Catch (..)
    , catchForm
    ) where

import Control.Applicative ((<$>), (<*>))
import Control.Monad.Reader (Reader, ask, runReader)

import Data.Text (Text)

import Text.Digestive.Form

-- Maximum level
type TrainerM = Reader Int

-- Default max level: 20
runTrainerM :: TrainerM a -> a
runTrainerM = flip runReader 20

data Type = Water | Fire | Leaf
    deriving (Eq, Show)

typeForm :: Monad m => Form m Text Type
typeForm = choice [(Water, "Water"), (Fire, "Fire"), (Leaf, "Leaf")] Nothing

data Pokemon = Pokemon
    { pokemonName  :: Text
    , pokemonLevel :: Int
    , pokemonType  :: Type
    , pokemonRare  :: Bool
    } deriving (Eq, Show)

levelForm :: Form TrainerM Text Int
levelForm =
    checkM "This pokemon will not obey you!" checkMaxLevel $
    check  "Level should be at least 1"      (> 1)         $
    stringRead "Cannot parse level" (Just 5)
  where
    checkMaxLevel l = do
        maxLevel <- ask
        return $ l <= maxLevel

pokemonForm :: Form TrainerM Text Pokemon
pokemonForm = Pokemon
    <$> "name"  .: text Nothing
    <*> "level" .: levelForm
    <*> "type"  .: typeForm
    <*> "rare"  .: bool False

data Ball = Poke | Great | Ultra | Master
    deriving (Eq, Show)

ballForm :: Monad m => Form m Text Ball
ballForm = choice
    [(Poke, "Poke"), (Great, "Great"), (Ultra, "Ultra"), (Master, "Master")]
    Nothing

data Catch = Catch
    { catchPokemon :: Pokemon
    , catchBall    :: Ball
    } deriving (Eq, Show)

catchForm :: Form TrainerM Text Catch
catchForm = check "You need a better ball" canCatch $ Catch
    <$> "pokemon" .: pokemonForm
    <*> "ball"    .: ballForm

canCatch :: Catch -> Bool
canCatch (Catch (Pokemon _ _ _ False) _)      = True
canCatch (Catch (Pokemon _ _ _ True)  Ultra)  = True
canCatch (Catch (Pokemon _ _ _ True)  Master) = True
canCatch _                                    = False
