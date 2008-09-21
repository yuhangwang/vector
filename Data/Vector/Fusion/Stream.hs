{-# LANGUAGE ExistentialQuantification, FlexibleInstances #-}

-- |
-- Module      : Data.Vector.Fusion.Stream
-- Copyright   : (c) Roman Leshchinskiy 2008
-- License     : BSD-style
--
-- Maintainer  : rl@cse.unsw.edu.au
-- Stability   : experimental
-- Portability : non-portable
-- 
-- Fusible streams
--

#include "phases.h"

module Data.Vector.Fusion.Stream (
  -- * Types
  Step(..), Stream, MStream, Id(..),

  -- * Size hints
  size, sized,

  -- * Length information
  length, null,

  -- * Construction
  empty, singleton, cons, snoc, replicate, (++),

  -- * Accessing individual elements
  head, last, (!!),

  -- * Substreams
  extract, init, tail, take, drop,

  -- * Mapping and zipping
  map, zipWith,

  -- * Filtering
  filter, takeWhile, dropWhile,

  -- * Searching
  elem, notElem, find, findIndex,

  -- * Folding
  foldl, foldl1, foldl', foldl1', foldr, foldr1,

  -- * Unfolding
  unfold,

  -- * Scans
  prescanl, prescanl',

  -- * Conversion to/from lists
  toList, fromList,

  -- * Monadic combinators
  mapM_, foldM
) where

import Data.Vector.Fusion.Stream.Size
import Data.Vector.Fusion.Stream.Monadic ( Step(..) )
import qualified Data.Vector.Fusion.Stream.Monadic as M

import Prelude hiding ( length, null,
                        replicate, (++),
                        head, last, (!!),
                        init, tail, take, drop,
                        map, zipWith,
                        filter, takeWhile, dropWhile,
                        elem, notElem,
                        foldl, foldl1, foldr, foldr1,
                        mapM_ )


newtype Id a = Id { unId :: a }

instance Functor Id where
  fmap f (Id x) = Id (f x)

instance Monad Id where
  return     = Id
  Id x >>= f = f x

-- | The type of fusible streams
type Stream = M.Stream Id

type MStream = M.Stream

liftStream :: Monad m => Stream a -> M.Stream m a
{-# INLINE_STREAM liftStream #-}
liftStream (M.Stream step s sz) = M.Stream (return . unId . step) s sz

-- | 'Size' hint of a 'Stream'
size :: Stream a -> Size
{-# INLINE size #-}
size = M.size

-- | Attach a 'Size' hint to a 'Stream'
sized :: Stream a -> Size -> Stream a
{-# INLINE sized #-}
sized = M.sized

-- | Convert a 'Stream' to a list
toList :: Stream a -> [a]
{-# INLINE toList #-}
toList s = unId (M.toList s)

-- | Create a 'Stream' from a list
fromList :: [a] -> Stream a
{-# INLINE fromList #-}
fromList = M.fromList

-- Length
-- ------

-- | Length of a 'Stream'
length :: Stream a -> Int
{-# INLINE length #-}
length = unId . M.length

-- | Check if a 'Stream' is empty
null :: Stream a -> Bool
{-# INLINE null #-}
null = unId . M.null

-- Construction
-- ------------

-- | Empty 'Stream'
empty :: Stream a
{-# INLINE empty #-}
empty = M.empty

-- | Singleton 'Stream'
singleton :: a -> Stream a
{-# INLINE singleton #-}
singleton = M.singleton

-- | Replicate a value to a given length
replicate :: Int -> a -> Stream a
{-# INLINE_STREAM replicate #-}
replicate = M.replicate

-- | Prepend an element
cons :: a -> Stream a -> Stream a
{-# INLINE cons #-}
cons = M.cons

-- | Append an element
snoc :: Stream a -> a -> Stream a
{-# INLINE snoc #-}
snoc = M.snoc

infixr 5 ++
-- | Concatenate two 'Stream's
(++) :: Stream a -> Stream a -> Stream a
{-# INLINE (++) #-}
(++) = (M.++)

-- Accessing elements
-- ------------------

-- | First element of the 'Stream' or error if empty
head :: Stream a -> a
{-# INLINE head #-}
head = unId . M.head

-- | Last element of the 'Stream' or error if empty
last :: Stream a -> a
{-# INLINE last #-}
last = unId . M.last

-- | Element at the given position
(!!) :: Stream a -> Int -> a
{-# INLINE (!!) #-}
s !! i = unId (s M.!! i)

-- Substreams
-- ----------

-- | Extract a substream of the given length starting at the given position.
extract :: Stream a -> Int   -- ^ starting index
                    -> Int   -- ^ length
                    -> Stream a
{-# INLINE extract #-}
extract = M.extract

-- | All but the last element
init :: Stream a -> Stream a
{-# INLINE init #-}
init = M.init

-- | All but the first element
tail :: Stream a -> Stream a
{-# INLINE tail #-}
tail = M.tail

-- | The first @n@ elements
take :: Int -> Stream a -> Stream a
{-# INLINE take #-}
take = M.take

-- | All but the first @n@ elements
drop :: Int -> Stream a -> Stream a
{-# INLINE drop #-}
drop = M.drop

-- Mapping/zipping
-- ---------------

-- | Map a function over a 'Stream'
map :: (a -> b) -> Stream a -> Stream b
{-# INLINE map #-}
map = M.map

-- | Zip two 'Stream's with the given function
zipWith :: (a -> b -> c) -> Stream a -> Stream b -> Stream c
{-# INLINE zipWith #-}
zipWith = M.zipWith

-- Filtering
-- ---------

-- | Drop elements which do not satisfy the predicate
filter :: (a -> Bool) -> Stream a -> Stream a
{-# INLINE filter #-}
filter = M.filter

-- | Longest prefix of elements that satisfy the predicate
takeWhile :: (a -> Bool) -> Stream a -> Stream a
{-# INLINE takeWhile #-}
takeWhile = M.takeWhile

-- | Drop the longest prefix of elements that satisfy the predicate
dropWhile :: (a -> Bool) -> Stream a -> Stream a
{-# INLINE dropWhile #-}
dropWhile = M.dropWhile

-- Searching
-- ---------

infix 4 `elem`
-- | Check whether the 'Stream' contains an element
elem :: Eq a => a -> Stream a -> Bool
{-# INLINE elem #-}
elem x = unId . M.elem x

infix 4 `notElem`
-- | Inverse of `elem`
notElem :: Eq a => a -> Stream a -> Bool
{-# INLINE notElem #-}
notElem x = unId . M.notElem x

-- | Yield 'Just' the first element matching the predicate or 'Nothing' if no
-- such element exists.
find :: (a -> Bool) -> Stream a -> Maybe a
{-# INLINE find #-}
find f = unId . M.find f

-- | Yield 'Just' the index of the first element matching the predicate or
-- 'Nothing' if no such element exists.
findIndex :: (a -> Bool) -> Stream a -> Maybe Int
{-# INLINE findIndex #-}
findIndex f = unId . M.findIndex f

-- Folding
-- -------

-- | Left fold
foldl :: (a -> b -> a) -> a -> Stream b -> a
{-# INLINE foldl #-}
foldl f z = unId . M.foldl f z

-- | Left fold on non-empty 'Stream's
foldl1 :: (a -> a -> a) -> Stream a -> a
{-# INLINE foldl1 #-}
foldl1 f = unId . M.foldl1 f

-- | Left fold with strict accumulator
foldl' :: (a -> b -> a) -> a -> Stream b -> a
{-# INLINE foldl' #-}
foldl' f z = unId . M.foldl' f z

-- | Left fold on non-empty 'Stream's with strict accumulator
foldl1' :: (a -> a -> a) -> Stream a -> a
{-# INLINE foldl1' #-}
foldl1' f = unId . M.foldl1' f

-- | Right fold
foldr :: (a -> b -> b) -> b -> Stream a -> b
{-# INLINE foldr #-}
foldr f z = unId . M.foldr f z

-- | Right fold on non-empty 'Stream's
foldr1 :: (a -> a -> a) -> Stream a -> a
{-# INLINE foldr1 #-}
foldr1 f = unId . M.foldr1 f

-- Unfolding
-- ---------

-- | Unfold
unfold :: (s -> Maybe (a, s)) -> s -> Stream a
{-# INLINE unfold #-}
unfold = M.unfold

-- Scans
-- -----

-- | Prefix scan
prescanl :: (a -> b -> a) -> a -> Stream b -> Stream a
{-# INLINE prescanl #-}
prescanl = M.prescanl

-- | Prefix scan with strict accumulator
prescanl' :: (a -> b -> a) -> a -> Stream b -> Stream a
{-# INLINE prescanl' #-}
prescanl' = M.prescanl'

-- Comparisons
-- -----------

eq :: Eq a => Stream a -> Stream a -> Bool
{-# INLINE_STREAM eq #-}
eq (M.Stream step1 s1 _) (M.Stream step2 s2 _) = eq_loop0 s1 s2
  where
    eq_loop0 s1 s2 = case unId (step1 s1) of
                       Yield x s1' -> eq_loop1 x s1' s2
                       Skip    s1' -> eq_loop0   s1' s2
                       Done        -> null (M.Stream step2 s2 Unknown)

    eq_loop1 x s1 s2 = case unId (step2 s2) of
                         Yield y s2' -> x == y && eq_loop0   s1 s2'
                         Skip    s2' ->           eq_loop1 x s1 s2'
                         Done        -> False

cmp :: Ord a => Stream a -> Stream a -> Ordering
{-# INLINE_STREAM cmp #-}
cmp (M.Stream step1 s1 _) (M.Stream step2 s2 _) = cmp_loop0 s1 s2
  where
    cmp_loop0 s1 s2 = case unId (step1 s1) of
                        Yield x s1' -> cmp_loop1 x s1' s2
                        Skip    s1' -> cmp_loop0   s1' s2
                        Done        -> if null (M.Stream step2 s2 Unknown)
                                         then EQ else LT

    cmp_loop1 x s1 s2 = case unId (step2 s2) of
                          Yield y s2' -> case x `compare` y of
                                           EQ -> cmp_loop0 s1 s2'
                                           c  -> c
                          Skip    s2' -> cmp_loop1 x s1 s2'
                          Done        -> GT

instance Eq a => Eq (M.Stream Id a) where
  {-# INLINE (==) #-}
  (==) = eq

instance Ord a => Ord (M.Stream Id a) where
  {-# INLINE compare #-}
  compare = cmp

-- Monadic combinators
-- -------------------

-- | Apply a monadic action to each element of the stream
mapM_ :: Monad m => (a -> m ()) -> Stream a -> m ()
{-# INLINE_STREAM mapM_ #-}
mapM_ f = M.mapM_ f . liftStream

-- | Monadic fold
foldM :: Monad m => (a -> b -> m a) -> a -> Stream b -> m a
{-# INLINE_STREAM foldM #-}
foldM m z = M.foldM m z . liftStream

