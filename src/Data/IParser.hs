{-# LANGUAGE Safe #-}
module Data.IParser where

import Data.Profunctor

data IParser r w c a =
  IParser { decoder :: r a
          , encoder :: Star w c a
          }

parser :: r a -> (c -> w a) -> IParser r w c a
parser dec enc = IParser { decoder = dec, encoder = Star enc }

decode :: IParser r w c a -> r a
decode = decoder

encode :: IParser r w c a -> c -> w a
encode = runStar . encoder

instance (Functor w, Functor r) => Functor (IParser r w c) where
  fmap f i = IParser { decoder = f <$> decoder i
                     , encoder = f <$> encoder i
                     }

instance (Applicative w, Applicative r) => Applicative (IParser r w c) where
  pure x = IParser { decoder = pure x, encoder = pure x }
  fx <*> x = IParser { decoder = decoder fx <*> decoder x, encoder = encoder fx <*> encoder x }

instance (Functor r, Functor w) => Profunctor (IParser r w) where
  dimap f g i = IParser { decoder = g <$> decoder i, encoder = dimap f g (encoder i) }

(.=) :: (Functor r, Functor w) => (c -> c') -> IParser r w c' a -> IParser r w c a
(.=) = lmap
