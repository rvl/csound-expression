-- | Instrument control
module Csound.Typed.Core.Opcodes.Instr
  ( active
  , maxalloc
  , nstrnum
  , turnoff2
  , schedule
  ) where

import Data.Maybe

import Csound.Dynamic (IfRate (..))
import Csound.Dynamic (Rate (..))

import Csound.Typed.Core.Types

-- | active — Returns the number of active instances of an instrument.
active :: (Arg a, SigOrD b) => InstrRef a -> SE b
active instrRef = case getInstrRefId instrRef  of
  Left strId  -> liftOpcDep "active" strRates strId
  Right intId -> liftOpcDep "active" intRates intId
  where
    intRates = [(Ir, [Ir,Ir,Ir]), (Kr, [Kr,Ir,Ir])]
    strRates = [(Ir, [Sr,Ir,Ir])]

-- | maxalloc — Limits the number of allocations of an instrument.
-- It's often used with @global@
maxalloc :: (Arg a) => InstrRef a -> D -> SE ()
maxalloc instrRef val = case getInstrRefId instrRef of
  Left strId -> liftOpcDep_ "maxalloc" strRates (strId, val)
  Right intId -> liftOpcDep_ "maxalloc" intRates (intId, val)
  where
    strRates = [(Xr, [Sr,Ir])]
    intRates = [(Xr, [Ir,Ir])]

-- | nstrnum — Returns the number of a named instrument
nstrnum :: Arg a => InstrRef a -> D
nstrnum instrRef = case getInstrRefId instrRef of
  Left strId -> liftOpc "nstrnum" [(Ir,[Sr])] strId
  Right intId -> intId

-- | turnoff2 — Turn off instance(s) of other instruments at performance time.
turnoff2 :: Arg a => InstrRef a -> Sig -> Sig -> SE ()
turnoff2 instrRef kmode krelease = do
  curRate <- fromMaybe IfIr <$> getCurrentRate
  case curRate of
    IfIr ->
      case getInstrRefId instrRef of
        Left strId  -> liftOpcDep_ "turnoff2" strRates (strId, kmode, krelease)
        Right intId -> liftOpcDep_ "turnoff2" intRates (intId, kmode, krelease)
    IfKr ->
      case getInstrRefId instrRef of
        Left strId  -> liftOpcDep_ "turnoff2_i" strRates_i (strId, kmode, krelease)
        Right intId -> liftOpcDep_ "turnoff2_i" intRates_i (intId, kmode, krelease)
  where
    strRates = [(Xr, [Sr,Kr,Kr])]
    intRates = [(Xr, [Kr,Kr,Kr])]
    strRates_i = [(Xr, [Sr,Ir,Ir])]
    intRates_i = [(Xr, [Ir,Ir,Ir])]

schedule :: (Arg a) => InstrRef a -> D -> D -> a -> SE ()
schedule instrId start dur args = play instrId [Note start dur args]
