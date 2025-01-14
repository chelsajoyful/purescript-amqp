module Node.AMQP
  ( module Node.AMQP.Types
  , module Node.AMQP
  ) where

import Node.AMQP.FFI (ECb, SCb, _ack, _ackAll, _assertExchange, _assertQueue, _bindExchange, _bindQueue, _cancel, _checkExchange, _checkQueue, _close, _closeChannel, _connect, _consume, _createChannel, _deleteExchange, _deleteQueue, _get, _nack, _nackAll, _onChannelClose, _onChannelDrain, _onChannelError, _onChannelReturn, _onConnectionBlocked, _onConnectionClose, _onConnectionError, _onConnectionUnblocked, _prefetch, _publish, _purgeQueue, _recover, _sendToQueue, _unbindExchange, _unbindQueue)
import Node.AMQP.Types (AssertQueueOK, Channel, ConnectOptions, Connection, ConsumeOK, ConsumeOptions, DeleteExchangeOptions, DeleteQueueOK, DeleteQueueOptions, ExchangeName, ExchangeOptions, ExchangeType(..), GetOptions, Message, MessageFields, MessageProperties, PublishOptions, PurgeQueueOK, QueueName, QueueOptions, RoutingKey, defaultConnectOptions, defaultConsumeOptions, defaultDeleteExchangeOptions, defaultDeleteQueueOptions, defaultExchangeOptions, defaultGetOptions, defaultPublishOptions, defaultQueueOptions)
import Node.AMQP.Types.Internal (connectUrl, encodeConsumeOptions, encodeDeleteExchangeOptions, encodeDeleteQueueOptions, encodeExchangeOptions, encodeGetOptions, encodePublishOptions, encodeQueueOptions, toMessage)
import Prelude (Unit, const, flip, map, show, unit, ($), ($>), (<<<), (>>>))

import Effect (Effect)
import Effect.Aff (Aff, makeAff, nonCanceler)

import Effect.Class (liftEffect)
import Effect.Exception (Error, message)
import Control.Monad.Error.Class (withResource)
import Foreign (Foreign)
import Foreign.Object (Object)
import Foreign.Class (encode)
import Data.Either
import Data.Function.Uncurried (runFn1, runFn2, runFn3, runFn4, runFn5, runFn6, runFn7)
import Data.Maybe (Maybe)
import Data.Nullable (toMaybe)
import Data.String (Pattern(..), contains)
import Node.Buffer (Buffer)

-- | Function to replace the Makeaff functions to allow this to compile with the lates purescript-aff file
toAff :: forall a. (ECb Unit -> SCb a Unit -> Effect Unit) -> Aff a
toAff p = makeAff \cb -> p (cb <<< Left) (cb <<< Right) $> nonCanceler

-- | Connects to an AMQP server given an AMQP URL and [connection options]. Returns the connection in
-- | `Aff` monad. See [amqplib docs](http://www.squaremobius.net/amqp.node/channel_api.html#connect) for details.
connect :: String -> ConnectOptions -> Aff Connection
connect url = toAff <<< runFn3 _connect <<< connectUrl url

-- | Closes the given AMQP connection.
-- | See [amqplib docs](http://www.squaremobius.net/amqp.node/channel_api.html#model_close) for details.
close :: Connection -> Aff Unit
close conn = toAff $ \onError onSuccess -> flip (runFn3 _close conn) onSuccess \err -> do
  if contains (Pattern "Connection closed") (message err)
    then onSuccess unit
    else onError err

-- | Creates an open channel and returns it.
-- | See [amqplib docs](http://www.squaremobius.net/amqp.node/channel_api.html#model_createChannel) for details.
createChannel :: Connection -> Aff Channel
createChannel = toAff <<< runFn3 _createChannel

-- | Closes the given channel.
-- | See [amqplib docs](http://www.squaremobius.net/amqp.node/channel_api.html#channel_close) for details.
closeChannel :: Channel -> Aff Unit
closeChannel = toAff <<< runFn3 _closeChannel

-- | Asserts a queue into existence with the given name and options.
-- | See [amqplib docs](http://www.squaremobius.net/amqp.node/channel_api.html#channel_assertQueue) for details.
assertQueue :: Channel -> QueueName -> QueueOptions -> Aff AssertQueueOK
assertQueue channel queue =
  toAff <<< runFn5 _assertQueue channel queue <<< encodeQueueOptions

-- | Checks that a queue exists with the given queue name.
-- | See [amqplib docs](http://www.squaremobius.net/amqp.node/channel_api.html#channel_checkQueue) for details.
checkQueue :: Channel -> QueueName -> Aff AssertQueueOK
checkQueue channel = toAff <<< runFn4 _checkQueue channel

-- | Deletes the queue by the given name.
-- | See [amqplib docs](http://www.squaremobius.net/amqp.node/channel_api.html#channel_deleteQueue) for details.
deleteQueue :: Channel -> QueueName -> DeleteQueueOptions -> Aff DeleteQueueOK
deleteQueue channel queue =
  toAff <<< runFn5 _deleteQueue channel queue <<< encodeDeleteQueueOptions

-- | Purges the messages from the queue by the given name.
-- | See [amqplib docs](http://www.squaremobius.net/amqp.node/channel_api.html#channel_purgeQueue) for details.
purgeQueue :: Channel -> QueueName -> Aff PurgeQueueOK
purgeQueue channel = toAff <<< runFn4 _purgeQueue channel

-- | Asserts a routing path from an exchange to a queue: the given exchange will relay
-- | messages to the given queue, according to the type of the exchange and the given routing key.
-- | See [amqplib docs](http://www.squaremobius.net/amqp.node/channel_api.html#channel_bindQueue) details.
bindQueue :: Channel -> QueueName -> ExchangeName -> RoutingKey -> Object Foreign -> Aff Unit
bindQueue channel queue exchange routingKey =
  toAff <<< runFn7 _bindQueue channel queue exchange routingKey <<< encode

-- | Removes the routing path between the given queue and the given exchange with the given routing key and arguments.
-- | See [amqplib docs](http://www.squaremobius.net/amqp.node/channel_api.html#channel_unbindQueue) for details.
unbindQueue :: Channel -> QueueName -> ExchangeName -> RoutingKey -> Object Foreign -> Aff Unit
unbindQueue channel queue exchange routingKey =
  toAff <<< runFn7 _unbindQueue channel queue exchange routingKey <<< encode

-- | Asserts an exchange into existence with the given exchange name, type and options.
-- | See [amqplib docs](http://www.squaremobius.net/amqp.node/channel_api.html#channel_assertExchange) for details.
assertExchange :: Channel -> ExchangeName -> ExchangeType -> ExchangeOptions -> Aff Unit
assertExchange channel exchange exchangeType =
  toAff <<< runFn6 _assertExchange channel exchange (show exchangeType) <<< encodeExchangeOptions

-- | Checks that the exchange exists by the given name.
-- | See [amqplib docs](http://www.squaremobius.net/amqp.node/channel_api.html#channel_checkExchange) for details.
checkExchange :: Channel -> ExchangeName -> Aff Unit
checkExchange channel = toAff <<< runFn4 _checkExchange channel

-- | Deletes the exchange by the given name.
-- | See [amqplib docs](http://www.squaremobius.net/amqp.node/channel_api.html#channel_deleteExchange) for details.
deleteExchange :: Channel -> ExchangeName -> DeleteExchangeOptions -> Aff Unit
deleteExchange channel exchange =
  toAff <<< runFn5 _deleteExchange channel exchange <<< encodeDeleteExchangeOptions

-- | Binds an exchange to another exchange. The exchange named by `destExchange` will receive messages
-- | from the exchange named by `sourceExchange`, according to the type of the source and the given
-- | routing key.
-- | See [amqplib docs](http://www.squaremobius.net/amqp.node/channel_api.html#channel_bindExchange) for details.
bindExchange :: Channel -> ExchangeName -> ExchangeName -> RoutingKey -> Object Foreign -> Aff Unit
bindExchange channel destExchange sourceExchange routingKey =
  toAff <<< runFn7 _bindExchange channel destExchange sourceExchange routingKey <<< encode

-- | Removes a binding from an exchange to another exchange.
-- | See [amqplib docs](http://www.squaremobius.net/amqp.node/channel_api.html#channel_unbindExchange) for details.
unbindExchange :: Channel -> ExchangeName -> ExchangeName -> RoutingKey -> Object Foreign -> Aff Unit
unbindExchange channel destExchange sourceExchange routingKey =
  toAff <<< runFn7 _unbindExchange channel destExchange sourceExchange routingKey <<< encode

-- | Publish a single message to the given exchange with the given routing key, and the given publish
-- | options. The message content is given as a `Buffer`.
-- | See [amqplib docs](http://www.squaremobius.net/amqp.node/channel_api.html#channel_publish) for details.
publish :: Channel -> ExchangeName -> RoutingKey -> Buffer -> PublishOptions -> Aff Unit
publish channel exchange routingKey buffer =
  toAff <<< const <<< runFn6 _publish channel exchange routingKey buffer <<< encodePublishOptions

-- | Sends a single message with the content given as a `Buffer` to the given queue, bypassing routing.
-- | See [amqplib docs](http://www.squaremobius.net/amqp.node/channel_api.html#channel_sendToQueue) for details.
sendToQueue :: Channel -> QueueName -> Buffer -> PublishOptions -> Aff Unit
sendToQueue channel queue buffer =
  toAff <<< const <<< runFn5 _sendToQueue channel queue buffer <<< encodePublishOptions

-- | Sets up a consumer for the given queue and consume options, with a callback to be invoked with each message.
-- | The callback receives `Nothing` if the consumer is cancelled by the broker. Returns the consumer tag.
-- | See [amqplib docs](http://www.squaremobius.net/amqp.node/channel_api.html#channel_consume) for details.
consume :: Channel -> QueueName -> ConsumeOptions -> (Maybe Message -> Effect Unit) -> Aff ConsumeOK
consume channel queue options onMessage =
  toAff $ runFn6 _consume channel queue (toMaybe >>> map toMessage >>> onMessage) (encodeConsumeOptions options)

-- | Cancels the consumer identified by the given consumer tag.
-- | See [amqplib docs](http://www.squaremobius.net/amqp.node/channel_api.html#channel_cancel) for details.
cancel :: Channel -> String -> Aff Unit
cancel channel = toAff <<< runFn4 _cancel channel

-- | Gets a message from the given queue. If there are no messages in the queue, returns `Nothing`.
-- | See [amqplib docs](http://www.squaremobius.net/amqp.node/channel_api.html#channel_get) for details.
get :: Channel -> QueueName -> GetOptions -> Aff (Maybe Message)
get channel queue opts = toAff \onError onSuccess ->
  runFn5 _get channel queue (encodeGetOptions opts) onError (onSuccess <<< map toMessage <<< toMaybe)

-- | Acknowledges a message given its delivery tag.
-- | See [amqplib docs](http://www.squaremobius.net/amqp.node/channel_api.html#channel_ack) for details.
ack :: Channel -> String -> Effect Unit
ack channel deliveryTag = runFn3 _ack channel deliveryTag false

-- | Acknowledges all messages up to the message with the given delivery tag.
-- | See [amqplib docs](http://www.squaremobius.net/amqp.node/channel_api.html#channel_ack) for details.
ackAllUpTo :: Channel -> String -> Effect Unit
ackAllUpTo channel deliveryTag = runFn3 _ack channel deliveryTag true

-- | Acknowledges all outstanding messages on the channel.
-- | See [amqplib docs](http://www.squaremobius.net/amqp.node/channel_api.html#channel_ackAll) for details.
ackAll :: Channel -> Effect Unit
ackAll = runFn1 _ackAll

-- | Rejects a message given its delivery tag. If the boolean param is true, the server requeues the
-- | message, else it drops it.
-- | See [amqplib docs](http://www.squaremobius.net/amqp.node/channel_api.html#channel_nack) for details.
nack :: Channel -> String -> Boolean -> Effect Unit
nack channel deliveryTag = runFn4 _nack channel deliveryTag false

-- | Rejects all messages up to the message with the given delivery tag. If the boolean param is true,
-- | the server requeues the messages, else it drops them.
-- | See [amqplib docs](http://www.squaremobius.net/amqp.node/channel_api.html#channel_nack) for details.
nackAllUpTo :: Channel -> String -> Boolean -> Effect Unit
nackAllUpTo channel deliveryTag = runFn4 _nack channel deliveryTag true

-- | Rejects all outstanding messages on the channel. If the boolean param is true,
-- | the server requeues the messages, else it drops them.
-- | See [amqplib docs](http://www.squaremobius.net/amqp.node/channel_api.html#channel_nackAll) for details.
nackAll :: Channel -> Boolean -> Effect Unit
nackAll = runFn2 _nackAll

-- | Sets the prefetch count for this channel.
-- | See [amqplib docs](http://www.squaremobius.net/amqp.node/channel_api.html#channel_prefetch) for details.
prefetch :: Channel -> Int -> Aff Unit
prefetch channel = liftEffect <<< runFn2 _prefetch channel

-- | Requeues unacknowledged messages on this channel.
-- | See [amqplib docs](http://www.squaremobius.net/amqp.node/channel_api.html#channel_recover) for details.
recover :: Channel -> Aff Unit
recover = toAff <<< runFn3 _recover

-- | Registers an event handler to the connection which is triggered when the connection closes.
-- | If the connection closes because of an error, the handler is called with `Just error`, else
-- | with `Nothing`.
-- | See [amqplib docs](http://www.squaremobius.net/amqp.node/channel_api.html#model_events) for details.
onConnectionClose :: Connection -> (Maybe Error -> Effect Unit) -> Effect Unit
onConnectionClose conn onClose = runFn2 _onConnectionClose conn (onClose <<< toMaybe)

-- | Registers an event handler to the connection which is triggered when the connection errors out.
-- | The handler is called with the error.
onConnectionError :: Connection -> (Error -> Effect Unit) -> Effect Unit
onConnectionError = runFn2 _onConnectionError

-- | Registers an event handler to the connection which is triggered when the RabbitMQ server
-- | decides to block the connection. The handler is called with the reason for blocking.
onConnectionBlocked :: Connection -> (String -> Effect Unit) -> Effect Unit
onConnectionBlocked = runFn2 _onConnectionBlocked

-- | Registers an event handler to the connection which is triggered when the RabbitMQ server
-- | decides to unblock the connection. The handler is called with no arguments.
onConnectionUnblocked :: Connection -> Effect Unit -> Effect Unit
onConnectionUnblocked = runFn2 _onConnectionUnblocked

-- | Registers an event handler to the channel which is triggered when the channel closes.
-- | The handler is called with no arguments.
-- | See [amqplib docs](http://www.squaremobius.net/amqp.node/channel_api.html#channel_events) for details.
onChannelClose :: Channel -> Effect Unit -> Effect Unit
onChannelClose = runFn2 _onChannelClose

-- | Registers an event handler to the channel which is triggered when the channel errors out.
-- | The handler is called with the error.
onChannelError :: Channel -> (Error -> Effect Unit) -> Effect Unit
onChannelError = runFn2 _onChannelError

-- | Registers an event handler to the channel which is triggered when a message published with
-- | the mandatory flag cannot be routed and is returned to the sending channel. The handler is
-- | called with the returned message.
onChannelReturn :: Channel -> (Message -> Effect Unit) -> Effect Unit
onChannelReturn channel onReturn = runFn2 _onChannelReturn channel (toMessage >>> onReturn)

-- | Registers an event handler to the channel which is triggered when the channel's write buffer
-- | is emptied. The handler is called with no arguments.
onChannelDrain :: Channel -> Effect Unit -> Effect Unit
onChannelDrain = runFn2 _onChannelDrain

-- | A convenience function for creating a channel, doing some action with it, and then automatically closing
-- | it, even in case of errors.
withChannel :: forall a. Connection -> (Channel -> Aff a) -> Aff a
withChannel conn = withResource (createChannel conn) closeChannel
