var activeChat;
var chats;
var chatsStr;
var scrollBottom = false;

function renderActiveChat() {
    var chatMessagesEl = document.getElementById("chat-messages");
    var messagesHtml = "";
    
    for(var i = 0; i < activeChat.messages.length; i++) {
        var cssClass = "message-remote";
        var from = "Myself";
        
        if (activeChat.messages[i].isMe === true && activeChat.service == "iMessage") {
            cssClass = "message-me-imessage";
        } else if (activeChat.messages[i].isMe === true) {
            cssClass = "message-me-sms";
        } else {
            from = activeChat.messages[i].from;
        }
        
        var itemHtml = "<div class='" + cssClass + "'><h4>" + from + "</h4><h4 class='message-date'>" + activeChat.messages[i].received + "</h4><p>" + activeChat.messages[i].body + "</p></div>";
        messagesHtml = itemHtml + messagesHtml;
    }
    
    chatMessagesEl.innerHTML = messagesHtml;
    
    if (scrollBottom) {
        var chatMessagesEl = document.getElementById("selected-chat");
        chatMessagesEl.scrollTop = chatMessagesEl.scrollHeight;
        scrollBottom = false;
    }
}

function setActiveChat(index) {
    activeChat = chats[index];
    if (activeChat) {
        activeChat.messagesStr = "";
    }
    scrollBottom = true;
    renderChats();
    loadMessages(activeChat.id);
    
    var noSelectedChatEl = document.getElementById("no-selected-chat");
    noSelectedChatEl.style.display = "none";
    
    var selectedChatEl = document.getElementById("selected-chat");
    selectedChatEl.style.display = "block";
}

function renderChats() {
    var chatListEl = document.getElementById("chat-list");
    var listHtml = "";
    
    for(var i = 0; i < chats.length; i++) {
        var cssClass = "chat-list-item";
        if (activeChat && activeChat.id == chats[i].id) {
            cssClass += " chat-list-item-active";
        }
        var itemHtml = "<div class='" + cssClass + "' onClick='setActiveChat(" + i + ")'><h2>" + chats[i].name + "</h2><h3>" + chats[i].lastMessage + "</h3><h4>" + chats[i].lastReceived + "</h4></div>";
        listHtml += itemHtml;
    }
    
    chatListEl.innerHTML = listHtml;
}

function refresh() {
    load();
    
    if (activeChat) {
        loadMessages(activeChat.id);
    }
}

function loadCallback(status, text) {
    var newChats = JSON.parse(text);
    if (text != chatsStr) {
        chats = newChats;
        chatsStr = text;
        renderChats();
    }
}

function load() {
    xhrExecute("GET", "messages?limit=20", "", loadCallback);
}

function loadMessagesCallback(status, text) {
    var newMessages = JSON.parse(text);
    
    if (newMessages.length > 0 && newMessages[0].chatId != activeChat.id) {
        // User changed the active chat before the response came
        return;
    }
    
    if (text != activeChat.messagesStr) {
        activeChat.messages = newMessages;
        activeChat.messagesStr = text;
        renderActiveChat();
    }
}

function loadMessages(chatId) {
    xhrExecute("GET", "messages/" + chatId + "?limit=20", "", loadMessagesCallback);
}

function sendMessageCallback(status, text) {
    loadMessages(activeChat.id);
    document.getElementById("message-input").value = "";
    load();
}

function sendMessage(event) {
    if (event.preventDefault) {
        event.preventDefault();
    }
    
    var body = {
        address: activeChat.replyId,
        service: activeChat.service,
        message: document.getElementById("message-input").value
    }
    xhrExecute("POST", "messages", body, sendMessageCallback);
}

function xhrExecute(method, endpoint, body, callback) {
    var xhr;
    
    if (window.XMLHttpRequest) {
        xhr = new XMLHttpRequest();
    } else {
        // IE support
        try {
            xhr = new ActiveXObject("Msxml2.XMLHTTP");
        } catch (e) {
            try {
                xhr = new ActiveXObject("Microsoft.XMLHTTP");
            } catch (ex) {
                // XMLHttpRequest not supported
                alert("Sorry! This browser cannot load Message Bridge :(");
            }
        }
    }
    
    var url = '/' + endpoint;
    
    xhr.open(method, url);
    xhr.onreadystatechange = function() {
        if (xhr.readyState == 4 && xhr.status == 200) {
            callback(xhr.status, xhr.responseText);
        }
    };
    xhr.setRequestHeader("Content-Type", "application/json;charset=UTF-8");
    xhr.send(JSON.stringify(body));
}

load();
setInterval(refresh, 3000);
