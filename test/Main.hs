{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TupleSections #-}
module Main (main) where

import System.Exit
       (exitFailure, exitSuccess)

import Data.Functor.Identity

import Hedgehog

import qualified Hedgehog.Gen as Gen
import qualified Hedgehog.Range as Range

import Control.Monad.Reader
       (ReaderT(..), runReaderT)
import Control.Monad.State
       (StateT(..), evalStateT)
import Control.Monad.Writer
       (Writer, execWriter, tell)
import Text.Read
       (readMaybe)

import Data.IParser

-- fmap id == id
prop_functor_identity :: Property
prop_functor_identity = property $ do
  x <- forAll $ Gen.integral (Range.linear 0 100)
  let p = parser (pure x) pure :: IParser Identity Identity Int Int
  decode (fmap id p) === id (decode p)
  encode (fmap id p) x === id (encode p x)

-- fmap (f . g) == fmap f . fmap g
prop_functor_composition :: Property
prop_functor_composition = property $ do
  x <- forAll $ Gen.integral (Range.linear 0 100)
  y <- forAll $ Gen.integral (Range.linear 0 100)
  z <- forAll $ Gen.integral (Range.linear 0 100)
  let p = parser (pure val) pure :: IParser Identity Identity (Int, (Int, Int)) (Int, (Int, Int))
      f = fst
      g = snd
      val = (x,(y,z))
  decode (fmap (f . g) p) === decode (fmap f . fmap g $ p)
  encode (fmap (f . g) p) val === encode (fmap f . fmap g $ p) val

-- pure id <*> v
prop_applicative_identity :: Property
prop_applicative_identity = property $ do
  x <- forAll $ Gen.integral (Range.linear 0 100)
  let p = pure x :: IParser Identity Identity Int Int
  decode (pure id <*> p) === pure x

prop_bidirectional :: Property
prop_bidirectional = property $ do
  x <- forAll $ Gen.integral (Range.linear 0 100)
  let int = parser (ReaderT readMaybe) (\x -> x <$ tell [show x])
  runReaderT (decode int) (head (execWriter (encode int x))) === Just x

data Person
  = Person { name :: String, age :: Int }
  deriving (Show, Eq)

prop_compose :: Property
prop_compose = property $ do
  person <- forAll (Person <$> Gen.string (Range.linear 0 10) Gen.unicode <*> Gen.integral (Range.linear 10 30))
  let int = parser (StateT $ \(x:xs) -> (,xs) <$> readMaybe x) (\x -> x <$ tell [show x])
      string = parser (StateT $ \(x:xs) -> Just (x,xs)) (\x -> x <$ tell [x])
      p = Person <$> name .= string <*> age .= int
      encoded = execWriter (encode p person)
  evalStateT (decode p) encoded === Just person

main :: IO ()
main = do
  result <- checkParallel $$(discover)
  if result then exitSuccess else exitFailure
