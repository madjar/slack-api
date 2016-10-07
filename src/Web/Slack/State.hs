{-# LANGUAGE FlexibleContexts           #-}
{-# LANGUAGE FlexibleInstances          #-}
{-# LANGUAGE FunctionalDependencies     #-}
{-# LANGUAGE MultiParamTypeClasses      #-}
{-# LANGUAGE OverloadedStrings          #-}
{-# LANGUAGE RankNTypes                 #-}
{-# LANGUAGE ScopedTypeVariables        #-}
{-# LANGUAGE TemplateHaskell            #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
module Web.Slack.State where

import           Control.Applicative
import           Control.Concurrent
import           Control.Lens
import           Control.Monad.IO.Class
import qualified Control.Monad.State       as S
import qualified Network.WebSockets        as WS
import           Web.Slack.Types
import           Web.Slack.WebAPI (SlackConfig)
import Prelude

newtype Slack s a = Slack {runSlack :: S.StateT (SlackState s) IO a}
  deriving (Monad, Functor, Applicative, S.MonadState (SlackState s), MonadIO)

type SlackBot s =  Event -> Slack s ()

data Metainfo = Meta
              { _metaConnection :: WS.Connection -- ^ Websockets connection
              , _msgCounter :: MVar Int          -- ^ Unique message counter
              }

instance Show Metainfo where
  show (Meta _ b) = "Metainfo: " ++ "<connection> " ++ "<counter>"

data SlackState s = SlackState
                { _meta      :: Metainfo      -- ^ Information about the connection
                , _session   :: SlackSession  -- ^ Information about the session at the
                                                  -- start of the connection
                , _userState :: s             -- ^ User defined state
                , _config    :: SlackConfig   -- ^ A copy of the initial configuration
                } deriving Show


makeLenses ''SlackState
makeLenses ''Metainfo

slackLog :: Show a => a -> MonadIO m => m ()
slackLog = liftIO . print

nextId :: MVar Int -> IO Int
nextId c = modifyMVar c (\i -> return (i+1, i))

connection :: Lens' (SlackState s) WS.Connection
connection = meta . metaConnection
