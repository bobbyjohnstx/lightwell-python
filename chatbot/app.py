import random

from flask import Flask, render_template, request, jsonify

app = Flask(__name__)

RESPONSES = [
    "I can help you with that! Let me look up your account details.",
    "Your order #10492 is currently in transit. Expected delivery is Thursday.",
    "I've updated your contact preferences. You'll receive email confirmations only.",
    "Let me transfer you to our billing department for that request. One moment.",
    "Your subscription renews on December 1st. Would you like to make changes?",
    "I've applied a 15% discount to your next invoice as a courtesy.",
    "Our business hours are Monday-Friday, 8 AM to 6 PM Eastern.",
    "I've created support ticket #TK-7291 for your issue. You'll receive updates via email.",
    "Your account security settings have been updated successfully.",
    "Is there anything else I can help you with today?",
]


@app.route("/")
def index():
    return render_template("index.html")


@app.route("/chat", methods=["POST"])
def chat():
    data = request.get_json(silent=True) or {}
    user_message = data.get("message", "")
    if not user_message.strip():
        return jsonify({"response": "I didn't catch that. Could you rephrase?"})
    response = random.choice(RESPONSES)
    return jsonify({"response": response})


if __name__ == "__main__":
    import os
    debug = os.environ.get("FLASK_DEBUG", "false").lower() == "true"
    app.run(debug=debug, port=5001)
