# Content Reader 📱

A Flutter-based RSS feed reader application with built-in AI integration, REST API, and cross-platform support.

## Features

- 📰 **RSS/Atom Feed Reader** - Fetch and read articles from RSS feeds
- 📂 **Category Management** - Organize feeds into categories
- 💾 **Local Storage** - Save articles for offline reading
- 🔌 **Built-in REST API** - Control the app remotely on port 1212
- 🔐 **API Key Authentication** - Secure API access
- 🤖 **AI Summarization** - Summarize articles using OpenClaw
- 🌙 **Dark/Light Theme** - Toggle between dark and light mode
- 🔄 **Background Refresh** - Auto-fetch new articles in background

## New AI Features

### Setup
1. Enable **AI Summarization** in Settings
2. Enable **OpenClaw Integration** in Settings
3. Start the OpenClaw server:

```bash
# Terminal 1: Start OpenClaw gateway
openclaw gateway start

# Terminal 2: Start the HTTP server wrapper
cd ~/Projects/zed-openclaw/server
node openclaw-server.js
```

### Usage
- Open any article
- Tap the ✨ sparkle button to generate an AI summary
- The summary will be saved with the article

## Built-in REST API

The app runs a local API server on **port 1212** with the following endpoints:

### Authentication
All endpoints (except `/health`) require a Bearer token:
```
Authorization: Bearer YOUR_API_KEY
```

Get your API key from the app settings or call the regenerate endpoint.

### Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check (no auth) |
| GET | `/api-key` | Get current API key |
| POST | `/api-key/regenerate` | Generate new API key |
| GET | `/categories` | List all categories |
| POST | `/categories` | Create category |
| PUT | `/categories/<id>` | Update category |
| DELETE | `/categories/<id>` | Delete category |
| GET | `/feeds` | List all feeds |
| POST | `/feeds` | Create feed |
| PUT | `/feeds/<id>` | Update feed |
| DELETE | `/feeds/<id>` | Delete feed |
| GET | `/articles` | List all articles |
| GET | `/articles/saved` | List saved articles |
| GET | `/articles/unread/count` | Get unread count |
| PUT | `/articles/<id>` | Update article |
| DELETE | `/articles/<id>` | Delete article |

### Example: AI Integration

```python
import requests

API_KEY = "your_api_key_here"
BASE_URL = "http://localhost:1212"

headers = {"Authorization": f"Bearer {API_KEY}"}

# Get unread articles for AI summarization
response = requests.get(f"{BASE_URL}/articles", headers=headers)
articles = response.json()

for article in articles:
    if not article['isRead']:
        print(f"Title: {article['title']}")
        print(f"Summary: {article['summary']}")
        # Send to AI for processing...
```

## Getting Started

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run

# Run on specific platform
flutter run -d ios
flutter run -d android
flutter run -d macos
```

### Build for macOS
```bash
flutter build macos
# Output: build/macos/Build/Products/Release/content_reader_flutter.app

# Copy to Applications
cp -r build/macos/Build/Products/Release/content_reader_flutter.app /Applications/
```

## Tech Stack

- **Flutter** - UI framework (Material 3)
- **SQLite** - Local database
- **Shelf** - REST API server
- **webfeed_plus** - RSS/Atom parsing
- **OpenClaw** - AI summarization

## License

MIT
