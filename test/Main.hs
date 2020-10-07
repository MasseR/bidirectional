{-# LANGUAGE TemplateHaskell #-}
module Main (main) where

import System.Exit
       (exitFailure, exitSuccess)

import Data.Functor.Identity

import Hedgehog

import qualified Hedgehog.Gen as Gen
import qualified Hedgehog.Range as Range

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

main :: IO ()
main = do
  result <- checkParallel $$(discover)
  if result then exitSuccess else exitFailure
