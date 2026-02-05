"""
Main application entry point.
Initializes Flask app and registers routes.
"""

from flask import Flask

app = Flask(__name__)


@app.route('/')
def index():
    """Return welcome message."""
    return {'message': 'Hello, World!'}


if __name__ == '__main__':
    app.run(debug=True)
