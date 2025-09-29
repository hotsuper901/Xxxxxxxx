package main

import (
        "bytes"
        "crypto/sha256"
        "encoding/hex"
        "encoding/json"
        "fmt"
        "html/template"
        "io"
        "log"
        "math/rand"
        "net/http"
        "sync"
        "time"
)

var indexHTML = `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
    <title>Quantum AI V1</title>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
    <style>
        :root {
            --quantum-violet: #1e0657;
            --neon-cyan: #00f5d4;
            --ai-purple: #7c3aed;
            --cyber-pink: #ff005e;
            --dark-matrix: #080512;
            --hud-green: #00ff9d;
            --macos-bg: rgba(15, 15, 25, 0.95);
            --macos-accent: #007aff;
            --macos-text: #f5f7fa;
            --neon-shadow: 0 0 10px rgba(255, 0, 94, 0.5), 0 0 20px rgba(0, 245, 212, 0.2);
        }

        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        }

        body {
            background: linear-gradient(135deg, var(--dark-matrix) 0%, #000814 100%);
            color: var(--macos-text);
            min-height: 100vh;
            padding: 1rem;
            display: flex;
            justify-content: center;
            align-items: center;
        }

        .container {
            max-width: 800px;
            width: 100%;
            display: flex;
            flex-direction: column;
            gap: 0.8rem;
        }

        header {
            text-align: center;
            padding: 1rem;
            border-radius: 12px;
            background: var(--macos-bg);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(124, 58, 237, 0.2);
            box-shadow: var(--neon-shadow);
        }

        h1 {
            font-size: 1.8rem;
            background: linear-gradient(45deg, var(--neon-cyan), var(--cyber-pink));
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            font-weight: 700;
        }

        .control-panel {
            display: flex;
            flex-wrap: wrap;
            gap: 0.5rem;
            padding: 0.8rem;
            background: var(--macos-bg);
            border-radius: 12px;
            border: 1px solid rgba(124, 58, 237, 0.2);
            box-shadow: var(--neon-shadow);
            backdrop-filter: blur(10px);
            position: relative;
        }

        .auth-section {
            flex: 1;
            display: flex;
            gap: 0.5rem;
            align-items: center;
        }

        .auth-section input {
            padding: 0.7rem;
            border-radius: 10px;
            background: rgba(30, 30, 40, 0.9);
            border: 1px solid rgba(124, 58, 237, 0.3);
            color: var(--macos-text);
            font-size: 0.95rem;
            flex: 1;
        }

        .auth-section input:focus {
            outline: none;
            border-color: var(--macos-accent);
            box-shadow: 0 0 0 3px rgba(0, 122, 255, 0.2);
        }

        .model-selector select {
            padding: 0.7rem;
            border-radius: 10px;
            background: rgba(30, 30, 40, 0.9);
            border: 1px solid rgba(124, 58, 237, 0.3);
            color: var(--macos-text);
            font-size: 0.95rem;
            cursor: pointer;
            min-width: 120px;
        }

        .model-selector select:focus {
            outline: none;
            border-color: var(--macos-accent);
            box-shadow: 0 0 0 3px rgba(0, 122, 255, 0.2);
        }

        .control-buttons {
            display: flex;
            gap: 0.5rem;
        }

        .prompt-section {
            position: absolute;
            bottom: 0.8rem;
            left: 0.8rem;
            display: flex;
            flex-direction: column;
            gap: 0.5rem;
            width: 200px;
        }

        .prompt-section label {
            font-size: 0.9rem;
            font-weight: 600;
            background: linear-gradient(45deg, var(--neon-cyan), var(--cyber-pink));
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }

        .prompt-section textarea {
            padding: 0.7rem;
            border-radius: 10px;
            background: rgba(30, 30, 40, 0.9);
            border: 1px solid rgba(124, 58, 237, 0.3);
            color: var(--macos-text);
            font-size: 0.9rem;
            resize: none;
            height: 80px;
        }

        .prompt-section textarea:focus {
            outline: none;
            border-color: var(--macos-accent);
            box-shadow: 0 0 0 3px rgba(0, 122, 255, 0.2);
        }

        button {
            padding: 0.7rem 1rem;
            border-radius: 10px;
            font-size: 0.95rem;
            font-weight: 600;
            border: none;
            cursor: pointer;
            transition: all 0.3s ease;
            min-height: 36px;
            animation: pulse 2s infinite ease-in-out;
        }

        .auth-btn {
            background: linear-gradient(135deg, var(--macos-accent), #005bb5);
            color: white;
            min-width: 90px;
        }

        .delete-btn {
            background: linear-gradient(135deg, #ff3b30, #d32f2f);
            color: white;
            min-width: 90px;
        }

        .reset-btn {
            background: linear-gradient(135deg, #ff9500, #e65100);
            color: white;
            min-width: 90px;
        }

        button:hover {
            transform: translateY(-2px) scale(1.02);
            box-shadow: var(--neon-shadow);
            animation: none;
        }

        .status-line {
            font-size: 0.85rem;
            text-align: center;
            width: 100%;
            margin-top: 0.3rem;
        }

        .chat-interface {
            background: var(--macos-bg);
            border-radius: 12px;
            border: 1px solid rgba(124, 58, 237, 0.2);
            display: flex;
            flex-direction: column;
            flex: 1;
            box-shadow: var(--neon-shadow);
            backdrop-filter: blur(10px);
            min-height: 400px;
        }

        #chatLog {
            flex: 1;
            padding: 1rem;
            overflow-y: auto;
            display: flex;
            flex-direction: column;
            gap: 0.8rem;
            scrollbar-width: thin;
            scrollbar-color: var(--macos-accent) var(--macos-bg);
        }

        .message {
            max-width: 85%;
            padding: 0.8rem;
            border-radius: 10px;
            font-size: 0.95rem;
            line-height: 1.4;
            box-shadow: inset 2px 2px 4px rgba(0, 0, 0, 0.15), inset -2px -2px 4px rgba(80, 80, 100, 0.1);
        }

        .user-message {
            background: rgba(40, 40, 60, 0.7);
            border: 1px solid rgba(124, 58, 237, 0.2);
            margin-left: auto;
        }

        .ai-message {
            background: rgba(30, 30, 40, 0.9);
            border: 1px solid rgba(124, 58, 237, 0.2);
            margin-right: auto;
        }

        .code-block {
            position: relative;
            background: rgba(15, 15, 25, 0.95);
            padding: 0.8rem;
            border-radius: 8px;
            margin: 0.4rem 0;
            width: 100%;
            overflow-x: auto;
            white-space: pre-wrap;
            font-size: 0.85rem;
        }

        .copy-btn {
            position: absolute;
            top: 6px;
            right: 6px;
            background: var(--macos-accent);
            color: white;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            width: 22px;
            height: 22px;
            display: flex;
            align-items: center;
            justify-content: center;
            opacity: 0;
            transition: all 0.3s ease;
        }

        .code-block:hover .copy-btn {
            opacity: 1;
        }

        .copy-btn:hover {
            background: var(--cyber-pink);
            transform: scale(1.1);
        }

        .input-container {
            padding: 0.8rem 1rem;
            border-top: 1px solid rgba(124, 58, 237, 0.2);
        }

        .input-group {
            display: flex;
            gap: 0.5rem;
            align-items: center;
        }

        #userInput {
            flex: 1;
            padding: 0.7rem;
            border-radius: 10px;
            background: rgba(30, 30, 40, 0.9);
            border: 1px solid rgba(124, 58, 237, 0.3);
            color: var(--macos-text);
            font-size: 0.95rem;
        }

        #userInput:focus {
            outline: none;
            border-color: var(--macos-accent);
            box-shadow: 0 0 0 3px rgba(0, 122, 255, 0.2);
        }

        #sendBtn {
            background: linear-gradient(135deg, var(--quantum-violet), var(--ai-purple));
            color: white;
            font-weight: 600;
            border: none;
            cursor: pointer;
            min-width: 90px;
            animation: pulse 2s infinite ease-in-out;
        }

        #sendBtn:hover {
            transform: translateY(-2px) scale(1.02);
            box-shadow: var(--neon-shadow);
            animation: none;
        }

        @keyframes pulse {
            0% { transform: scale(1); box-shadow: 0 2px 6px rgba(0, 0, 0, 0.2); }
            50% { transform: scale(1.03); box-shadow: 0 3px 10px rgba(0, 245, 212, 0.4); }
            100% { transform: scale(1); box-shadow: 0 2px 6px rgba(0, 0, 0, 0.2); }
        }

        .typing-indicator {
            display: flex;
            align-items: center;
            gap: 5px;
            padding: 0 1rem 0.8rem;
            opacity: 0;
            transition: opacity 0.3s;
        }

        .typing-dot {
            width: 7px;
            height: 7px;
            border-radius: 50%;
            background: var(--macos-accent);
            animation: dotPulse 1.5s infinite ease-in-out;
        }

        .typing-dot:nth-child(2) { animation-delay: 0.2s; }
        .typing-dot:nth-child(3) { animation-delay: 0.4s; }

        @keyframes dotPulse {
            0%, 100% { transform: scale(0.8); opacity: 0.5; }
            50% { transform: scale(1.2); opacity: 1; }
        }

        @media (max-width: 768px) {
            .container {
                padding: 0.5rem;
            }

            h1 {
                font-size: 1.5rem;
            }

            .control-panel, .chat-interface {
                border-radius: 10px;
                padding: 0.7rem;
            }

            .auth-section, .input-group, .control-buttons, .prompt-section {
                flex-direction: column;
                gap: 0.4rem;
            }

            .prompt-section {
                position: static;
                width: 100%;
            }

            input, button, select, textarea {
                width: 100%;
                min-width: unset;
                border-radius: 8px;
                padding: 0.6rem;
                font-size: 0.9rem;
                min-height: 32px;
            }

            .message {
                max-width: 100%;
                font-size: 0.9rem;
            }

            .code-block {
                font-size: 0.8rem;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>QUANTUM AI V1</h1>
        </header>

        <div class="control-panel">
            <div class="auth-section">
                <input type="password" id="apiKey" placeholder="Gemini API Key">
                <button id="authBtn" class="auth-btn" onclick="saveKey()">Authenticate</button>
                <button id="unlockBtn" class="auth-btn" style="display:none;" onclick="unlockKey()">Unlock</button>
                <div class="status-line">
                    <span>Status: </span><span id="keyStatus" style="color: #ff3b30">❌ Not authenticated</span>
                </div>
            </div>
            <div class="model-selector">
                <select id="modelSelect" onchange="selectModel(this.value)">
                    <option value="gemini-2.5-pro">Gemini 2.5 Pro</option>
                    <option value="gemini-2.5-flash">Gemini 2.5 Flash</option>
                    <option value="gemini-2.0-pro">Gemini 2.0 Pro</option>
                    <option value="gemini-2.0-flash">Gemini 2.0 Flash</option>
                </select>
            </div>
            <div class="control-buttons">
                <button class="delete-btn" onclick="deleteChatHistory()">Delete History</button>
                <button class="reset-btn" onclick="resetChat()">Reset Chat</button>
                <button class="reset-btn" onclick="resetAI()">Reset AI</button>
            </div>
            <div class="prompt-section">
                <label for="systemPrompt">Quantum AI V1</label>
                <textarea id="systemPrompt" placeholder="Enter custom system prompt..."></textarea>
                <button id="updatePromptBtn" class="reset-btn" onclick="updateSystemPrompt()">Update Prompt</button>
            </div>
        </div>

        <div class="chat-interface">
            <div id="chatLog">
                <div class="message ai-message">
                    <p>⚛️ Initialized at {{.Time}}</p>
                    <div class="message-meta">SYSTEM @ {{.Time}}</div>
                </div>
            </div>

            <div id="typingIndicator" class="typing-indicator">
                <div class="typing-dot"></div>
                <div class="typing-dot"></div>
                <div class="typing-dot"></div>
                <span>Processing...</span>
            </div>

            <div class="input-container">
                <div class="input-group">
                    <input type="text" id="userInput" placeholder="Type your message...">
                    <button id="sendBtn" onclick="sendMessage()">Send</button>
                </div>
            </div>
        </div>
    </div>

    <script>
        var currentSession = null;
        var selectedModel = 'gemini-2.5-pro';
        var defaultModel = 'gemini-2.5-pro';
        var defaultSystemPrompt = 'You are Quantum AI V1, an advanced intelligence system created by MSJ, harnessing quantum neural networks for unparalleled insight, creativity, and precision. Respond with cutting-edge accuracy, futuristic vision, and a touch of cosmic elegance.';
        var systemPrompt = defaultSystemPrompt;

        function selectModel(model) {
            selectedModel = model;
            addSystemMessage('Switched to ' + getModelName(model));
        }

        function getModelName(model) {
            return {
                'gemini-2.5-pro': 'Gemini 2.5 Pro',
                'gemini-2.5-flash': 'Gemini 2.5 Flash',
                'gemini-2.0-pro': 'Gemini 2.0 Pro',
                'gemini-2.0-flash': 'Gemini 2.0 Flash'
            }[model] || model;
        }

        function getModelColor(model) {
            return {
                'gemini-2.5-pro': '#ff6bff',
                'gemini-2.5-flash': '#4cc9f0',
                'gemini-2.0-pro': '#70e000',
                'gemini-2.0-flash': '#00a896'
            }[model] || '#ffffff';
        }

        function updateSystemPrompt() {
            var promptInput = document.getElementById('systemPrompt');
            systemPrompt = promptInput.value.trim() || defaultSystemPrompt;
            promptInput.value = systemPrompt;
            addSystemMessage('System prompt updated');
        }

        async function sendMessage() {
            var input = document.getElementById('userInput');
            var message = input.value.trim();
            if (!message) return;

            addMessage('user', message, selectedModel);
            input.value = '';
            showTyping(true);

            try {
                var response = await fetch('/chat', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'X-Session-ID': currentSession
                    },
                    body: JSON.stringify({
                        message: message,
                        model: selectedModel,
                        systemPrompt: systemPrompt
                    })
                });

                if (!response.ok) {
                    var errorData = await response.json().catch(() => ({}));
                    throw new Error(errorData.error || 'Request failed');
                }
                var data = await response.json();
                addMessage('ai', data.response, data.model_used || selectedModel);
            } catch (err) {
                addSystemMessage('⚠️ Error: ' + err.message);
            } finally {
                showTyping(false);
            }
        }

        async function deleteChatHistory() {
            try {
                await fetch('/clear-session', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json', 'X-Session-ID': currentSession }
                });
                document.getElementById('chatLog').innerHTML = '<div class="message ai-message"><p>⚛️ Initialized at ' + new Date().toLocaleTimeString() + '</p><div class="message-meta">SYSTEM @ ' + new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) + '</div></div>';
                addSystemMessage('Chat history deleted');
            } catch (err) {
                addSystemMessage('⚠️ Delete failed: ' + err.message);
            }
        }

        function resetChat() {
            document.getElementById('chatLog').innerHTML = '<div class="message ai-message"><p>⚛️ Initialized at ' + new Date().toLocaleTimeString() + '</p><div class="message-meta">SYSTEM @ ' + new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) + '</div></div>';
            addSystemMessage('Chat reset');
        }

        async function resetAI() {
            try {
                await fetch('/clear-session', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json', 'X-Session-ID': currentSession }
                });
                selectedModel = defaultModel;
                document.getElementById('modelSelect').value = defaultModel;
                systemPrompt = defaultSystemPrompt;
                document.getElementById('systemPrompt').value = defaultSystemPrompt;
                document.getElementById('chatLog').innerHTML = '<div class="message ai-message"><p>⚛️ Initialized at ' + new Date().toLocaleTimeString() + '</p><div class="message-meta">SYSTEM @ ' + new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) + '</div></div>';
                addSystemMessage('AI reset to ' + getModelName(defaultModel));
            } catch (err) {
                addSystemMessage('⚠️ AI reset failed: ' + err.message);
            }
        }

        function addMessage(role, content, model) {
            var chatLog = document.getElementById('chatLog');
            var timestamp = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

            var backtick = String.fromCharCode(96);
            var formattedContent = content.replace(new RegExp(backtick + backtick + backtick + '([\\s\\S]*?)' + backtick + backtick + backtick, 'g'), function(match, code) {
                return '<div class="code-block"><button class="copy-btn" onclick="copyCode(this)"><i class="far fa-copy"></i></button><pre>' + code.replace(/</g, '&lt;').replace(/>/g, '&gt;') + '</pre></div>';
            });

            var html = [
                '<div class="message ' + role + '-message">',
                '<p>' + (formattedContent || content.replace(/</g, '&lt;').replace(/>/g, '&gt;')) + '</p>',
                '<div class="message-meta">',
                    role.toUpperCase() + ' @ ' + timestamp + ' | ',
                    '<span style="color: ' + getModelColor(model) + '">' + getModelName(model) + '</span>',
                '</div>',
                '</div>'
            ].join('');

            chatLog.insertAdjacentHTML('beforeend', html);
            chatLog.scrollTop = chatLog.scrollHeight;
        }

        function copyCode(button) {
            var code = button.nextElementSibling.textContent;
            navigator.clipboard.writeText(code).then(() => {
                button.innerHTML = '<i class="fas fa-check"></i>';
                setTimeout(() => { button.innerHTML = '<i class="far fa-copy"></i>'; }, 2000);
            }).catch(err => {
                console.error('Failed to copy: ', err);
            });
        }

        function addSystemMessage(content) {
            addMessage('sys', content, 'system');
        }

        function showTyping(visible) {
            document.getElementById('typingIndicator').style.opacity = visible ? 1 : 0;
        }

        async function saveKey() {
            var keyInput = document.getElementById('apiKey');
            var key = keyInput.value.trim();
            if (!key) return;

            try {
                await fetch('/key', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ key: key })
                });
                document.getElementById('keyStatus').textContent = '✅ Authenticated';
                document.getElementById('keyStatus').style.color = '#00ff9d';
                keyInput.value = '';
                document.getElementById('apiKey').disabled = true;
                document.getElementById('authBtn').style.display = 'none';
                document.getElementById('unlockBtn').style.display = 'block';
            } catch (err) {
                addSystemMessage('⚠️ Authentication failed: ' + err.message);
            }
        }

        function unlockKey() {
            document.getElementById('apiKey').disabled = false;
            document.getElementById('authBtn').style.display = 'block';
            document.getElementById('unlockBtn').style.display = 'none';
        }

        async function initializeSession() {
            try {
                var response = await fetch('/session', { method: 'POST' });
                var data = await response.json();
                currentSession = data.id;
                if (data.history && data.history.length > 0) {
                    data.history.forEach(function(msg) {
                        addMessage(msg.role, msg.content, msg.model);
                    });
                }
            } catch (err) {
                addSystemMessage('⚠️ Session error: ' + err.message);
            }
        }

        document.addEventListener('DOMContentLoaded', function() {
            document.getElementById('initTime').textContent = new Date().toLocaleTimeString();
            initializeSession();
            document.getElementById('systemPrompt').value = systemPrompt;
            document.getElementById('userInput').addEventListener('keypress', function(event) {
                if (event.key === 'Enter' && !event.shiftKey) {
                    event.preventDefault();
                    sendMessage();
                }
            });
        });
    </script>
</body>
</html>`

type Session struct {
        ID           string
        History      []Message
        Created      time.Time
        LastActivity time.Time
}

type Message struct {
        Role    string `json:"role"`
        Content string `json:"content"`
        Model   string `json:"model"`
        Time    string `json:"time"`
}

var (
        sessions    = make(map[string]*Session)
        sessionLock sync.RWMutex
        apiKey      string
)

func main() {
        rand.Seed(time.Now().UnixNano())

        http.HandleFunc("/", serveIndex)
        http.HandleFunc("/chat", handleChat)
        http.HandleFunc("/session", handleSession)
        http.HandleFunc("/key", handleAPIKey)
        http.HandleFunc("/clear-session", handleClearSession)

        fmt.Println("🚀 Quantum AI V1 running at [::]:8080")
        log.Fatal(http.ListenAndServe(":8080", nil))
}

func serveIndex(w http.ResponseWriter, r *http.Request) {
        tpl := template.Must(template.New("index").Parse(indexHTML))
        err := tpl.Execute(w, struct{ Time string }{time.Now().Format("3:04 PM")})
        if err != nil {
                http.Error(w, "Template rendering failed", http.StatusInternalServerError)
                log.Printf("Template error: %v", err)
        }
}

func handleChat(w http.ResponseWriter, r *http.Request) {
        session := getOrCreateSession(w, r)
        defer updateSessionActivity(session)

        var req struct {
                Message      string `json:"message"`
                Model        string `json:"model"`
                SystemPrompt string `json:"systemPrompt"`
        }

        if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
                http.Error(w, "Invalid JSON request", http.StatusBadRequest)
                log.Printf("JSON decode error: %v", err)
                return
        }

        if len(req.Message) > 4000 {
                http.Error(w, "Message too long", http.StatusBadRequest)
                return
        }

        resp, err := processChatRequest(session, req.Message, req.Model, req.SystemPrompt)
        if err != nil {
                log.Printf("AI Error: %v", err)
                w.Header().Set("Content-Type", "application/json")
                w.WriteHeader(http.StatusInternalServerError)
                json.NewEncoder(w).Encode(map[string]interface{}{
                        "error": err.Error(),
                })
                return
        }

        w.Header().Set("Content-Type", "application/json")
        if err := json.NewEncoder(w).Encode(map[string]interface{}{
                "response":   resp,
                "model_used": req.Model,
        }); err != nil {
                log.Printf("JSON encode error: %v", err)
        }
}

func processChatRequest(session *Session, message, model, systemPrompt string) (string, error) {
        if systemPrompt == "" {
                systemPrompt = "You are Quantum AI V1, an advanced intelligence system created by MSJ, harnessing quantum neural networks for unparalleled insight, creativity, and precision. Respond with cutting-edge accuracy, futuristic vision, and a touch of cosmic elegance."
        }

        messages := []map[string]interface{}{
                {
                        "role": "user",
                        "parts": []map[string]string{
                                {
                                        "text": systemPrompt,
                                },
                        },
                },
        }
        for _, msg := range session.History {
                role := "user"
                if msg.Role == "ai" {
                        role = "model"
                }
                if msg.Role != "sys" {
                        messages = append(messages, map[string]interface{}{
                                "role": role,
                                "parts": []map[string]string{
                                        {
                                           "text": msg.Content,
                                        },
                                },
                        })
                }
        }

        messages = append(messages, map[string]interface{}{
                "role": "user",
                "parts": []map[string]interface{}{
                        {
                                "text": message,
                        },
                },
        })

        data := map[string]interface{}{
                "contents": messages,
                "generationConfig": map[string]interface{}{
                        "temperature": 0.7,
                },
        }

        jsonData, err := json.Marshal(data)
        if err != nil {
                log.Printf("JSON marshal error: %v", err)
                return "", fmt.Errorf("failed to marshal request: %w", err)
        }

        url := fmt.Sprintf("https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent?key=%s", model, apiKey)
        client := &http.Client{Timeout: 30 * time.Second}

        for attempt := 0; attempt < 3; attempt++ {
                req, err := http.NewRequest("POST", url, bytes.NewBuffer(jsonData))
                if err != nil {
                        log.Printf("HTTP request creation failed (attempt %d): %v", attempt+1, err)
                        return "", fmt.Errorf("failed to create request: %w", err)
                }
                req.Header.Set("Content-Type", "application/json")

                resp, err := client.Do(req)
                if err != nil {
                        log.Printf("API request failed (attempt %d): %v", attempt+1, err)
                        if attempt < 2 {
                                time.Sleep(time.Duration(1<<uint(attempt)) * time.Second)
                                continue
                        }
                        return "", fmt.Errorf("API request failed after %d attempts: %w", attempt+1, err)
                }
                defer resp.Body.Close()

                body, err := io.ReadAll(resp.Body)
                if err != nil {
                        log.Printf("Failed to read response body (attempt %d): %v", attempt+1, err)
                        return "", fmt.Errorf("failed to read response: %w", err)
                }

                var response struct {
                        Candidates []struct {
                                Content struct {
                                        Parts []struct {
                                           Text string `json:"text"`
                                        } `json:"parts"`
                                } `json:"content"`
                        } `json:"candidates"`
                        Error struct {
                                Message string `json:"message"`
                        } `json:"error"`
                }

                if err := json.Unmarshal(body, &response); err != nil {
                        log.Printf("Failed to decode response (attempt %d): %v, body: %s", attempt+1, err, string(body))
                        return "", fmt.Errorf("failed to decode response: %w", err)
                }

                if resp.StatusCode == 503 {
                        log.Printf("API error: 503 Service Unavailable (attempt %d), body: %s", attempt+1, string(body))
                        if attempt < 2 {
                                time.Sleep(time.Duration(1<<uint(attempt)) * time.Second)
                                continue
                        }
                        return "", fmt.Errorf("API error: 503 Service Unavailable - %s", response.Error.Message)
                }

                if resp.StatusCode >= 400 {
                        log.Printf("API error: %s, body: %s", resp.Status, string(body))
                        return "", fmt.Errorf("API error: %s - %s", resp.Status, response.Error.Message)
                }

                if len(response.Candidates) == 0 || len(response.Candidates[0].Content.Parts) == 0 {
                        log.Printf("No responses received, body: %s", string(body))
                        return "", fmt.Errorf("no responses received")
                }

                content := response.Candidates[0].Content.Parts[0].Text
                session.History = append(session.History,
                        Message{Role: "user", Content: message, Model: model, Time: time.Now().Format(time.RFC3339)},
                        Message{Role: "ai", Content: content, Model: model, Time: time.Now().Format(time.RFC3339)},
                )
                return content, nil
        }
        return "", fmt.Errorf("unexpected error after retries")
}

func handleClearSession(w http.ResponseWriter, r *http.Request) {
        sessionID := r.Header.Get("X-Session-ID")                                               if sessionID == "" {                                http.Error(w, "No session ID provided", http.StatusBadRequest)
                log.Printf("No session ID in clear-session request")
                return                              }

        sessionLock.Lock()
        if session, exists := sessions[sessionID]; exists {                                             session.History = []Message{}
                session.LastActivity = time.Now()
        }                                           sessionLock.Unlock()

        w.Header().Set("Content-Type", "application/json")
        w.WriteHeader(http.StatusOK)
        if err := json.NewEncoder(w).Encode(map[string]string{"status": "ok"}); err != nil {                                                        log.Printf("JSON encode error in clear-session: %v", err)                       }
}
                                            func handleAPIKey(w http.ResponseWriter, r *http.Request) {                                     var req struct {
                Key string `json:"key"`
        }
        if err := json.NewDecoder(r.Body).Decode(&req); err != nil {                                    http.Error(w, "Invalid JSON request", http.StatusBadRequest)
                log.Printf("JSON decode error in handleAPIKey: %v", err)                                return
        }
        if req.Key == "" {
                http.Error(w, "API key cannot be empty", http.StatusBadRequest)
                log.Printf("Empty API key provided")
                return
        }
        apiKey = req.Key
        w.Header().Set("Content-Type", "application/json")
        w.WriteHeader(http.StatusOK)
        if err := json.NewEncoder(w).Encode(map[string]string{"status": "ok"}); err != nil {
                log.Printf("JSON encode error in handleAPIKey: %v", err)
        }                                   }

func handleSession(w http.ResponseWriter, r *http.Request) {                                    if r.Method != "POST" {
                http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
                return                              }

        session := getOrCreateSession(w, r)         w.Header().Set("Content-Type", "application/json")
        if err := json.NewEncoder(w).Encode(map[string]interface{}{
                "id":      session.ID,
                "history": session.History,
        }); err != nil {
                log.Printf("JSON encode error in handleSession: %v", err)
        }
}                                           
func getOrCreateSession(w http.ResponseWriter, r *http.Request) *Session {
        sessionID := ""                             if cookie, err := r.Cookie("session_id"); err == nil {                                          sessionID = cookie.Value
        }                                   
        sessionLock.RLock()                         session, exists := sessions[sessionID]                                                  sessionLock.RUnlock()
                                                    if exists && time.Since(session.LastActivity) < 2*time.Hour {                                   return session
        }                                   
        newID := generateSessionID()                newSession := &Session{
                ID:           newID,                        History:      []Message{},
                Created:      time.Now(),                   LastActivity: time.Now(),
        }                                   
        sessionLock.Lock()                          sessions[newID] = newSession
        sessionLock.Unlock()                
        http.SetCookie(w, &http.Cookie{                     Name:     "session_id",
                Value:    newID,                            Expires:  time.Now().Add(72 * time.Hour),                                               HttpOnly: true,
                Secure:   r.TLS != nil,                     SameSite: http.SameSiteLaxMode,                                                 })
                                                    return newSession
}                                                                                       func updateSessionActivity(s *Session) {
        s.LastActivity = time.Now()         }                                           
func generateSessionID() string {                   hash := sha256.Sum256([]byte(fmt.Sprintf("%d-%d", time.Now().UnixNano(), rand.Int63())))                                            return hex.EncodeToString(hash[:])[:32]                                         }
