# Content Reader 📱

A Flutter-based RSS feed reader application with built-in AI integration, REST API, offline support, and cross-platform support.

## Features

### Core Features
- 📰 **RSS/Atom Feed Reader** - Fetch and read articles from RSS feeds
- 📂 **Category Management** - Organize feeds into categories with custom colors
- 💾 **Local Storage** - SQLite database for offline reading
- 🌙 **Dark/Light Theme** - Toggle between dark and light mode
- 🔍 **Full-Text Search** - Search articles by title, content, or summary

### API & Integration
- 🔌 **Built-in REST API** - Control the app remotely on port 1212
- 🔐 **API Key Authentication** - Secure API access with Bearer token
- 📦 **OPML Import/Export** - Backup and restore your feeds
- 🔄 **Feed Validation** - Validates RSS/Atom format before adding feeds

### AI Features
- 🤖 **AI Summarization** - Summarize articles using OpenClaw
- ⚡ **Configurable AI Server** - Set custom OpenClaw URL in settings
- 🔁 **Retry Logic** - Automatic retry with exponential backoff

### Performance
- ⚡ **Parallel Feed Fetching** - Multiple feeds fetched simultaneously
- 📄 **Pagination** - Fast article loading with lazy scroll
- 🔋 **Reliable Background Refresh** - WorkManager-powered background sync

## New AI Features

### Setup
1. Enable **AI Summarization** in Settings
2. Enable **OpenClaw Integration** in Settings
3. (Optional) Configure custom OpenClaw URL if not using localhost:3000

```bash
# Start OpenClaw gateway
openclaw gateway start
```

### Usage
- Open any article
- Tap the ✨ sparkle button to generate an AI summary
- The summary will be saved with the article

## Search Functionality

The app includes full-text search across all articles:

1. Go to **Articles** tab
2. Tap the 🔍 search icon in the app bar
3. Search by title, content, or summary
4. Results update in real-time

## OPML Import/Export

Backup and restore your feeds:

1. Go to **Settings** → **OPML Import/Export**
2. **Export**: Tap "Export to OPML" to share/save your feeds
3. **Import**: Tap "Import from OPML" to add feeds from a file

OPML is a standard format supported by most RSS readers (Feedly, Inoreader, etc.)

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

### Build for iOS
```bash
flutter build ios
# Output: build/ios/iphoneos/Runner.app
```

### Build for Android
```bash
flutter build apk
# Output: build/app/outputs/flutter-apk/app-release.apk
```

## Performance Notes

- **Pagination**: Articles are loaded in batches of 50 for optimal performance
- **Parallel Fetching**: Feeds are fetched in parallel (up to 5 concurrent) for faster updates
- **Background Refresh**: Uses WorkManager for reliable background sync every 15 minutes

## Tech Stack

- **Flutter** - UI framework (Material 3)
- **flutter_bloc** - State management (BLoC pattern)
- **SQLite** - Local database (sqflite)
- **Shelf** - REST API server
- **webfeed_plus** - RSS/Atom parsing
- **WorkManager** - Background task scheduling
- **OpenClaw** - AI summarization

## License

MIT
