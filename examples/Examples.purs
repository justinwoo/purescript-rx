module Examples where

import Prelude
import Control.MonadPlus.Partial
import Control.Monad.Error.Class
import Control.Monad.Eff.Exception (message, error)
import Data.Tuple (Tuple(..))
import Data.Maybe
import Control.Monad.Eff.Console (log, print)

import Rx.Notification
import Rx.Observable
import Rx.Observable.Aff
import Rx.Observable.Cont (liftCont)

main = do
  a <- return $ fromArray [1,2,3]
  b <- return $ fromArray [4,5,6]

  subscribe (a <> b) $ print

  subscribe (combineLatest (+) a b) $ print

  subscribe (zip (+) a b) (\n -> print $ "zip: " ++ show n)

  subscribe (reduce (+) 0 (zip (+) a b)) $ print

  subscribe (delay 1000 a) $ print

  let s = pure "OnNext" <> throwError (error "OnError")
  subscribe' s print (print <<< message) (const $ print "OnCompleted")

  let s' = pure (OnNext "OK") <> (pure $ OnError $ error "An error")
  subscribe' (dematerialize $ s') print (print <<< message) (const $ print "OnCompleted")

  subscribe (materialize $ pure "materialized" <> throwError (error "err")) print

  -- MonadError
  let err = throwError $ error "This is an error"
  subscribe (catchError err (pure <<< message)) print
  subscribeOnError err (print <<< message)

  -- Aff
  v <- liftAff $ pure "hello"
  runObservable $ print <$> v

  affE <- liftAff $ throwError $ error "This is an Aff error"
  subscribe (catchError affE (pure <<< message)) print
  
  -- ContT
  
  c <- liftCont $ pure (OnNext "hello from ContT")
  subscribe c print

  contE <- liftCont $ pure (OnError (error "error from ContT"))
  subscribe (catchError contE (pure <<< message)) print

  -- Plus
  (Tuple smaller bigger) <- return $ mpartition ((>) 5) (fromArray [2,3,4,5,6,8,9,10,100])

  log "smaller:"
  subscribe smaller $ print

  log "bigger:"
  subscribe bigger $ print

  subscribe (mcatMaybes $ fromArray [Just 1, Just 2, Nothing, Just 4]) $ print
