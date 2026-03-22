from flask import Flask, jsonify
import os

app = Flask(__name__)


@app.route('/health')
def health():
    return jsonify({"status": "ok"})


@app.route('/greet/<name>')
def greet(name):
    return jsonify({"message": f"Hello, {name}!"})


@app.route('/add/<int:a>/<int:b>')
def add(a, b):
    return jsonify({"result": a + b})


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
