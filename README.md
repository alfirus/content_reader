# Content Reader 📱

A Flutter-based RSS feed reader application with a built-in REST API for AI integration.

## Features

- 📰 **RSS/Atom Feed Reader** - Fetch and read articles from RSS feeds
- 📂 **Category Management** - Organize feeds into categories
- 💾 **Local Storage** - Save articles for offline reading
- 🔌 **Built-in REST API** - Control the app remotely
- 🔐 **API Key Authentication** - Secure API access

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

#### AI Article Summarization
```python
# Send article to AI and update with summary
def summarize_article(article_id, content):
    # Use your favorite AI API (OpenAI, Claude, Gemini, etc.)
    summary = call_ai_summarize(content)
    
    # Update article via API
    requests.put(
        f"{BASE_URL}/articles/{article_id}",
        headers=headers,
        json={"summary": summary}
    )
```

#### AI-Powered Feed Analysis
```python
# Get all feeds and analyze with AI
response = requests.get(f"{BASE_URL}/feeds", headers=headers)
feeds = response.json()

for feed in feeds:
    # Use AI to categorize or analyze feed content
    category = call_ai_categorize(feed['description'])
    # Update feed with AI-suggested category
```

## Getting Started

```bash
# Run the app
flutter run

# Run on specific platform
flutter run -d ios
flutter run -d android
```

## Tech Stack

- **Flutter** - UI framework
- **SQLite** - Local database
- **Shelf** - REST API server
- **webfeed_plus** - RSS/Atom parsing

## License

MIT
