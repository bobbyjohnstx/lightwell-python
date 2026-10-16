(function () {
    "use strict";

    const chatMessages = document.getElementById("chatMessages");
    const chatForm = document.getElementById("chatForm");
    const messageInput = document.getElementById("messageInput");
    const sendButton = document.getElementById("sendButton");

    let isWaitingForResponse = false;

    function formatTime() {
        return new Date().toLocaleTimeString([], {
            hour: "2-digit",
            minute: "2-digit",
        });
    }

    function scrollToBottom() {
        requestAnimationFrame(() => {
            chatMessages.scrollTop = chatMessages.scrollHeight;
        });
    }

    function createMessageElement(text, sender) {
        const wrapper = document.createElement("div");
        wrapper.className = "message message-" + sender;
        wrapper.setAttribute("role", "article");
        wrapper.setAttribute(
            "aria-label",
            (sender === "user" ? "You" : "Support agent") + " said"
        );

        const bubble = document.createElement("div");
        bubble.className = "message-bubble";
        bubble.textContent = text;

        const time = document.createElement("div");
        time.className = "message-time";
        time.textContent = formatTime();

        wrapper.appendChild(bubble);
        wrapper.appendChild(time);

        return wrapper;
    }

    function showTypingIndicator() {
        const indicator = document.createElement("div");
        indicator.className = "message message-bot";
        indicator.id = "typingIndicator";
        indicator.setAttribute("aria-label", "Support agent is typing");

        const dots = document.createElement("div");
        dots.className = "typing-indicator";

        for (let i = 0; i < 3; i++) {
            const dot = document.createElement("span");
            dot.className = "typing-dot";
            dots.appendChild(dot);
        }

        indicator.appendChild(dots);
        chatMessages.appendChild(indicator);
        scrollToBottom();
    }

    function removeTypingIndicator() {
        const indicator = document.getElementById("typingIndicator");
        if (indicator) {
            indicator.remove();
        }
    }

    function addMessage(text, sender) {
        const messageEl = createMessageElement(text, sender);
        chatMessages.appendChild(messageEl);
        scrollToBottom();
    }

    function setInputEnabled(enabled) {
        isWaitingForResponse = !enabled;
        messageInput.disabled = !enabled;
        sendButton.disabled = !enabled;

        if (enabled) {
            messageInput.focus();
        }
    }

    async function sendMessage(text) {
        if (!text.trim() || isWaitingForResponse) {
            return;
        }

        addMessage(text, "user");
        messageInput.value = "";
        setInputEnabled(false);

        // Brief pause before showing typing indicator for realism
        await new Promise((r) => setTimeout(r, 400));
        showTypingIndicator();

        try {
            const response = await fetch("/chat", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ message: text }),
            });

            if (!response.ok) {
                throw new Error("Server returned " + response.status);
            }

            const data = await response.json();

            // Simulate a natural reading/typing delay (800-1500ms)
            const delay = 800 + Math.random() * 700;
            await new Promise((r) => setTimeout(r, delay));

            removeTypingIndicator();
            addMessage(data.response, "bot");
        } catch (error) {
            console.error("Chat error:", error);
            removeTypingIndicator();
            addMessage(
                "Sorry, something went wrong. Please try again.",
                "bot"
            );
        } finally {
            setInputEnabled(true);
        }
    }

    // ── Event Listeners ──────────────────────────────────────

    chatForm.addEventListener("submit", function (e) {
        e.preventDefault();
        sendMessage(messageInput.value);
    });

    // ── Welcome Message ──────────────────────────────────────

    function init() {
        setTimeout(function () {
            addMessage("Hello! How can I help you today?", "bot");
        }, 500);

        messageInput.focus();
    }

    init();
})();
