-- | Primitive Csound types
module Csound.Typed.Core.Types.Prim
  ( SigOrD
  , module X
  -- * Converters
  , sig
  , toD
  , int
  -- * Constants
  , idur
  , getSampleRate
  , getControlRate
  , getBlockSize
  , getZeroDbfs
  -- * Utils
  , fromMono
  , toMono
  , ceil'
  , frac'
  , floor'
  , int'
  , round'
  , quot'
  , rem'
  , mod'
  , div'
  ) where

import Data.Boolean
import Csound.Dynamic (Name, Rate (..))
import Csound.Dynamic qualified as Dynamic
import Csound.Typed.Core.Types.Prim.Bool as X
import Csound.Typed.Core.Types.Prim.D as X
import Csound.Typed.Core.Types.Prim.Sig as X
import Csound.Typed.Core.Types.Prim.Tab as X
import Csound.Typed.Core.Types.Prim.Val as X
import Csound.Typed.Core.Types.Prim.Str as X
import Csound.Typed.Core.Types.Prim.Spec as X
import Csound.Typed.Core.Types.Prim.InstrId as X
import Csound.Typed.Core.Types.Tuple (Tuple)

class
  ( IsPrim a
  , BoolVal (BooleanOf a)
  , Tuple (BooleanOf a)
  , RealFrac (PrimOf a)
  , Tuple a
  , Val a
  , Floating a
  , OrdB a
  ) => SigOrD a where

instance SigOrD Sig
instance SigOrD D

-------------------------------------------------------------------------------
-- converters

sig :: D -> Sig
sig = \case
  D a     -> Sig a
  PrimD a -> PrimSig a

toD :: Sig -> D
toD = \case
  Sig a -> D a
  PrimSig a -> PrimD a

fromMono :: Sig -> (Sig, Sig)
fromMono a = (a, a)

toMono :: (Sig, Sig) -> Sig
toMono (a, b) = 0.5 * (a + b)

int :: SigOrD a => Int -> a
int = fromE . pure . Dynamic.int

-------------------------------------------------------------------------------
-- constants

-- | Querries a total duration of the note. It's equivallent to Csound's @p3@ field.
idur :: D
idur = fromE $ pure $ Dynamic.pn Ir 3

getSampleRate :: D
getSampleRate = readConstant "sr"

getControlRate :: D
getControlRate = readConstant "kr"

getBlockSize :: D
getBlockSize = readConstant "ksmps"

getZeroDbfs :: D
getZeroDbfs =  readConstant "0dbfs"

readConstant :: Val a => Name -> a
readConstant name = fromE $ pure $ Dynamic.readOnlyVar (Dynamic.VarVerbatim Ir name)

ceil', floor', int', round' :: SigOrD a => a -> a
quot', rem', div', mod' :: SigOrD a => a -> a -> a

frac' :: (SigOrD a) => a -> a
frac' a = liftPrim (\x -> proxySnd a (properFraction x)) Dynamic.fracE a
    where
        proxySnd :: SigOrD a => a -> (Int, PrimOf a) -> PrimOf a
        proxySnd _ x = snd x

ceil' = liftPrim (\x -> fromIntegral ((ceiling x) :: Int)) Dynamic.ceilE
floor' = liftPrim (\x -> fromIntegral ((floor x) :: Int)) Dynamic.floorE
int' = liftPrim (\x -> fromIntegral ((truncate x) :: Int)) Dynamic.intE
round' = liftPrim (\x -> fromIntegral ((round x) :: Int)) Dynamic.roundE
quot' = liftPrim2 (\a b -> fromIntegral $ quot ((truncate a) :: Int) ((truncate b):: Int)) quot
rem' = liftPrim2 (\a b -> fromIntegral $ rem ((truncate a) :: Int) ((truncate b):: Int)) rem
div' = liftPrim2 (\a b -> fromIntegral $ div ((truncate a) :: Int) ((truncate b):: Int)) div
mod' = liftPrim2 (\a b -> fromIntegral $ mod ((truncate a) :: Int) ((truncate b):: Int)) mod
