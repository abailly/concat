{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE AllowAmbiguousTypes #-}

{-# OPTIONS_GHC -Wall #-}
{-# OPTIONS_GHC -Wno-unused-imports #-} -- TEMP

-- | Experiment with learning from the notMNIST data set

module ConCat.RegressChoice where

import GHC.Types (Constraint)

import Data.Key

import ConCat.Misc (R,sqr,Unop,Binop,(:*),Yes1)
import ConCat.Free.VectorSpace
-- import ConCat.Free.LinearRow
-- import ConCat.Shaped

import ConCat.AD (gradient,IsScalar)

import ConCat.Choice

-- First do a simple linear regression

-- | Slope/intercept form of a line: y = m * x + b
type Line = (R,R)

type Fun = R -> R

-- | 1D linear function in slope/intercept for: y = m * x + b.
-- Defines a family of functions.
line :: Line -> Fun
line (m,b) x = m * x + b
{-# INLINE line #-}

-- -- Choose a 1D linear function. To be re-interpreted in a ChoiceCat.
-- chooseLine :: Fun
-- chooseLine = choose @(HasV R) line
-- -- chooseLine = choose @(HasV R) (\ (m,b) x -> m * x + b)
-- {-# INLINE chooseLine #-}

-- chooseLine :: forall con. (con Line, CartCon con) => Fun
-- -- chooseLine = choose @con (\ (m,b) x -> m * x + b)
-- chooseLine = choose @con line
-- {-# INLINE chooseLine #-}

type Sample = (R,R)

-- | Squared error for a single sample
sqErr :: (HasV s b, f ~ V s b, Zip f, Foldable f, Num s) => (a,b) -> (a -> b) -> s
-- sqErr (a,b) f = distSqr (toV (f a)) (toV b)
sqErr (a,b) f = distSqr' (f a) b
{-# INLINE sqErr #-}

-- sqErr :: Sample -> Fun -> R
-- -- sqErr :: (Num b) => (a,b) -> (a -> b) -> b
-- sqErr (a,b) f = sqr (f a - b)

-- lineErr :: Sample -> Line -> R
-- lineErr s = sqErr s . line

-- -- Given a data sample and candidate line, yield a delta moving the line toward the sample
-- step :: Sample -> Line -> Line
-- step s = negateV' @R . gradient (lineErr s)
-- -- step s l = negateV' @R (gradient (lineErr s) l)

step :: forall s p a b. ( Num s, IsScalar s, HasV s b, Zip (V s b), Foldable (V s b)
                        , HasV s p, Functor (V s p))
     => (p -> a -> b) -> (a,b) -> (p -> p)
step f ab = negateV' @s . gradient @s (\ p -> sqErr ab (f p))
{-# INLINE step #-}

--                                             f     :: p -> a -> b
--                        (\ p ->              f p)  :: p -> a -> b
--                        (\ p -> sqErr (a,b) (f p)) :: p -> s
--               gradient (\ p -> sqErr (a,b) (f p)) :: p -> p
-- negateV' @s . gradient (\ p -> sqErr (a,b) (f p)) :: p -> p


{--------------------------------------------------------------------
    Miscellany
--------------------------------------------------------------------}

negateV' :: forall s a. (HasV s a, Functor (V s a), Num s) => Unop a
negateV' = onV @s negateV

subV' :: forall s a. (HasV s a, Zip (V s a), Num s) => Binop a
subV' = onV2 @s subV

distSqr' :: (HasV s a, f ~ V s a, Zip f, Foldable f, Num s) => a -> a -> s
distSqr' a a' = distSqr (toV a) (toV a')