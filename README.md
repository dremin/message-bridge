# Message Bridge

A simple solution for accessing iMessage and SMS chats from older computers.

This is still a work-in-progress, but it works!

![Screenshot](screenshot.png)

## Requirements

Message Bridge runs on a modern Mac signed into iMessage. Once running, you can access it via a web browser on older computers.

1. Modern Mac to run Message Bridge:
   - macOS 10.15 or later (tested on macOS 13)
   - Messages signed into iMessage
2. Accessing Message Bridge on an old machine:
   - Connected to the same network as the modern Mac running Message Bridge
   - Running a web browser that supports `XMLHTTPRequest`:
     - Safari 1.2 or later (tested 1.3 and 3.0)
     - Camino (tested 1.0.6, 1.6.11, and 2.1.2)
     - Firefox (tested 1.0 and later)
     - Probably others!

## Installation

Perform the following steps on your modern Mac signed into iMessage.

1. Download from the [releases page](https://github.com/dremin/message-bridge/releases)
2. Uncompress the downloaded archive, then double-click `MessageBridge` to start Message Bridge.
3. **Important:** You must grant permissions so that Message Bridge can send messages, access received messages, and access contacts:
   - First, you will be prompted to allow Terminal to control Messages. Click OK.
   - Then, you will be prompted to allow Terminal to access contacts. Click OK.
   - Finally, we must manually enable Full Disk Access for Terminal. To do so, perform these steps:
     1. Open System Settings > Privacy & Security > Full Disk Access
     2. Find Terminal in the list, then click the toggle to enable it.
     3. You will be prompted to restart Terminal to provide full access. Click "Later"--we already have the necessary access.
4. All set! On the desired machine, open a web browser to the first URL in the Message Bridge window.

## Security

There is none, so don't configure your router NAT to port forward Message Bridge.

## REST API

If you'd like to integrate Message Bridge into your own client, you can use the REST API, which is the same API used by the provided web client.

### Getting chats

GET /messages

**Query parameters:**
- **limit** (default: 5) Controls the number of chats to return.

#### Response

Array of `Chat`:
- **id** Unique chat ID, used to request a chat's messages
- **replyId** Unique chat reply ID, used when sending a message to a chat
- **name** Display name for the chat (group name or recipient name)
- **lastMessage** Latest message received for the chat
- **lastReceived** Date/time the latest message was received
- **service** Service for the chat, `iMessage` or `SMS`

### Getting chat messages

GET /messages/{chatId}

**Query parameters:**
- **limit** (default: 5) Controls the number of chat messages to return.

#### Response

Array of `ChatMessage`:
- **id** Unique message ID
- **chatId** Unique chat ID
- **isMe** Boolean indicating if the message was sent by the local user
- **from** Chat participant who sent the message _(ignore if `isMe` is `true`)_
- **body** Message body text
- **lastReceived** Date/time the message was received

### Sending messages to a chat

POST /messages

**Headers:**
- **Content-Type:** application/json

**Parameters:**
- **address** Chat `replyId` retrieved from `GET /messages` (or address of desired recipient for a new chat)
- **service** Service for the chat, `iMessage` or `SMS`
- **message** Message body text
