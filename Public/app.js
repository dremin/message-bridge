var chatsLimit = 20;
var messagesLimit = 20;
var inlineImages = true;
var inlineImageMaxSize = 300;
var downloadScaledImages = true;
var downloadImageMaxSize = 1500;
var refreshInterval = 3000;

var activeChat;
var chats;
var latestId;

function renderActiveChat() {
    var chatMessagesEl = document.getElementById("chat-messages");
    var messagesHtml = "";
    
    for(var i = 0; i < activeChat.messages.length; i++) {
        var cssClass = "message";
        var from = "Myself";
        var attachmentHtml = "";
        
        if (activeChat.messages[i].isMe == false) {
            from = activeChat.messages[i].from;
        }
        
        if (activeChat.messages[i].attachments) {
            for (var j = 0; j < activeChat.messages[i].attachments.length; j++) {
                var attachment = activeChat.messages[i].attachments[j];
                var isImage = attachment.type == "image/gif" ||
                              attachment.type == "image/jpeg" ||
                              attachment.type == "image/png" ||
                              attachment.type == "image/tiff" ||
                              attachment.type == "image/heic";
                
                if (inlineImages && isImage) {
                    var attachmentUrl = "/attachments/" + attachment.id + "/thumb?download=true&maxSize=" + downloadImageMaxSize;
                    var attachmentImg = "/attachments/" + attachment.id + "/thumb?maxSize=" + inlineImageMaxSize;
                    if (attachment.type == "image/gif") {
                        // show thumbnails only for non-gifs: gifs are animated and usually smaller dimensions
                        attachmentUrl = "/attachments/" + attachment.id;
                        attachmentImg = "/attachments/" + attachment.id;
                    } else if (!downloadScaledImages) {
                        attachmentUrl = "/attachments/" + attachment.id;
                    }
                    // display images inline
                    attachmentHtml += "<a href='" + attachmentUrl + "' target='_blank'><img src='" + attachmentImg + "' alt='" + attachment.filename + "'></a>";
                } else {
                    // display button
                    var attachmentUrl = "/attachments/" + attachment.id;
                    if (downloadScaledImages && isImage) {
                        attachmentUrl = "/attachments/" + attachment.id + "/thumb?download=true&maxSize=" + downloadImageMaxSize;
                    }
                    attachmentHtml += "<p><a href='" + attachmentUrl + "' target='_blank'>" + attachment.filename + "</a></p>"
                }
            }
        }
        
        var itemHtml = "<div class='" + cssClass + "'><h4>" + from + "</h4><h4 class='message-date'>" + activeChat.messages[i].received + "</h4><p>" + activeChat.messages[i].body + "</p>" + attachmentHtml + "</div>";
        messagesHtml = itemHtml + messagesHtml;
    }
    chatMessagesEl.innerHTML = messagesHtml;
    
    // Scroll to the bottom
    var chatMessagesEl = document.getElementById("selected-chat");
    chatMessagesEl.scrollTop = chatMessagesEl.scrollHeight;
}

function setActiveChat(index) {
    activeChat = chats[index];
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
    
    for (var i = 0; i < chats.length; i++) {
        var cssClass = "chat-list-item";
        if (activeChat && activeChat.id == chats[i].id) {
            cssClass += " chat-list-item-active";
        }
        var itemHtml = "<div class='" + cssClass + "' onClick='setActiveChat(" + i + ")'><h2>" + chats[i].name + "</h2><h3>" + chats[i].lastMessage + "</h3><h4>" + chats[i].lastReceived + "</h4></div>";
        listHtml += itemHtml;
    }
    
    chatListEl.innerHTML = listHtml;
}

function loadChatsCallback(status, text) {
    chats = JSON.parse(text);
    
    if (chats.length > 0 && !latestId) {
        latestId = chats[0].lastMessageId;
    }
    
    renderChats();
}

function loadChats() {
    xhrExecute("GET", "chats?limit=" + chatsLimit, "", loadChatsCallback);
}

function loadMessagesCallback(status, text) {
    var newMessages = JSON.parse(text);
    
    if (newMessages.length > 0 && newMessages[0].chatId != activeChat.id) {
        // User changed the active chat before the response came
        return;
    }
    
    activeChat.messages = newMessages;
    renderActiveChat();
}

function loadMessages(chatId) {
    xhrExecute("GET", "chats/" + chatId + "/messages?format=true&limit=" + messagesLimit, "", loadMessagesCallback);
}

function loadLatestCallback(status, text) {
    if (text == latestId) {
        return;
    }
    
    latestId = text;
    loadChats();
    
    if (activeChat) {
        loadMessages(activeChat.id);
    }
}

function loadLatest() {
    // Add random number to query string to bust IE cache
    xhrExecute("GET", "chats/latest?rand=" + Math.floor(Math.random() * 10000), "", loadLatestCallback);
}

function sendMessageCallback(status, text) {
    loadMessages(activeChat.id);
    document.getElementById("message-input").value = "";
    document.getElementById("message-send").disabled = false;
    loadChats();
}

function sendMessage(event) {
    if (event.preventDefault) {
        event.preventDefault();
    }
    
    var body = {
        address: activeChat.replyId,
        isReply: true,
        message: document.getElementById("message-input").value
    }
    document.getElementById("message-send").disabled = true;
    xhrExecute("POST", "chats", body, sendMessageCallback);
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
                window.location.replace("/lite");
                return;
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

loadChats();
setInterval(loadLatest, refreshInterval);
