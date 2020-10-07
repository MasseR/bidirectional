{-# LANGUAGE Safe #-}
{-|
Module      : Data.IParser
Description : Bidirectional parsing
Copyright   : (c) Mats Rauhala, 2020
License     : BSD-3
Maintainer  : mats.rauhala@iki.fi
Stability   : experimental
Portability : POSIX

Let's assume we have a parser like the following

@
int :: Parser (ReaderT String Maybe) (Writer [Int]) Int Int
int = parser (ReaderT readMaybe) (\x -> x <$ tell [show x])
@

Then you can use the parser for parsing:

@
> runReaderT (decode int) "3"
Just 3
@

Or for encoding:

@
> execWriter (encode int 3)
["3"]
@

Or combine both of them

@
> runReaderT (decode int) $ head $ execWriter $ encode int 3
Just 3
@
-}
module Data.IParser where

import Data.Profunctor

-- | The core bidirectional parser type
--
-- See the module for usage example
--
data IParser r w c a =
  IParser { decoder :: r a -- ^ Return a value "a" in context "r".
          , encoder :: Star w c a -- ^ Generate a value "a" from the initial object "c" in the context "w"
          }

-- | Smart constructor for the parser
parser
  :: r a -- ^ The parser
  -> (c -> w a) -- ^ The encoder
  -> IParser r w c a
parser dec enc = IParser { decoder = dec, encoder = Star enc }

-- | Extract the decoder from the parser
decode :: IParser r w c a -> r a
decode = decoder

-- | Extract the encoder from the parser
encode :: IParser r w c a -> c -> w a
encode = runStar . encoder

-- | Record accessor helper
--
-- Due to the nature of the parser, the encoder gets the full record type, when
-- it should only focus on a specific part.
--
-- @
-- data Person = Person { name :: String, age :: Int }
--
-- person :: IParser r w Person Person
-- person =
--  Person <$> name .= string
--         <*> age .= int
-- @
(.=) :: (Functor r, Functor w) => (c -> c') -> IParser r w c' a -> IParser r w c a
(.=) = lmap

instance (Functor w, Functor r) => Functor (IParser r w c) where
  fmap f i = IParser { decoder = f <$> decoder i
                     , encoder = f <$> encoder i
                     }

instance (Applicative w, Applicative r) => Applicative (IParser r w c) where
  pure x = IParser { decoder = pure x, encoder = pure x }
  fx <*> x = IParser { decoder = decoder fx <*> decoder x, encoder = encoder fx <*> encoder x }

instance (Functor r, Functor w) => Profunctor (IParser r w) where
  dimap f g i = IParser { decoder = g <$> decoder i, encoder = dimap f g (encoder i) }

