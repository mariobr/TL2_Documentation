# Search Index Setup

The documentation viewer now includes full-text search powered by Lunr.js with a pre-built search index.

## How It Works

1. **Pre-built Index**: Documents are indexed ahead of time using `build-search-index.ps1`
2. **Fast Loading**: The viewer loads the pre-built `search-index.json` on startup
3. **Instant Search**: Search queries run against the in-memory index with no network requests

## Building the Search Index

### Manual Build

Run the build script whenever documents are added or modified:

```powershell
.\build-search-index.ps1
```

This will:
- Scan all markdown files in TL2, TL2_dotnet, TLCloud, and Generated folders
- Extract titles, headings, and content
- Create a searchable index at `search-index.json`

### Verbose Output

To see each document as it's indexed:

```powershell
.\build-search-index.ps1 -Verbose
```

### Custom Output Location

```powershell
.\build-search-index.ps1 -OutputFile "custom-index.json"
```

## Search Features

- **Full-text search** across all document content
- **Weighted results**: Titles and headings rank higher than body text
- **Relevance scoring**: Results sorted by match quality (0-100%)
- **Context snippets**: See where matches occur in documents
- **Highlighted matches**: Search terms highlighted in yellow
- **Live results**: Search as you type (300ms debounce)

## Using the Search

1. Open the documentation viewer
2. Type your search query in the header search box
3. Results appear automatically in the "Search Results" tab
4. Click any result to view the full document

## Automating Index Builds

### On Document Save (VSCode Task)

Add to `.vscode/tasks.json`:

```json
{
    "label": "Rebuild Search Index",
    "type": "shell",
    "command": ".\\build-search-index.ps1",
    "problemMatcher": []
}
```

### Git Pre-Commit Hook

Create `.git/hooks/pre-commit`:

```bash
#!/bin/sh
powershell.exe -File build-search-index.ps1
git add search-index.json
```

### Scheduled Task (Windows)

Run nightly at 2 AM:

```powershell
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File D:\DEV\TL2_Documentation\build-search-index.ps1"
$trigger = New-ScheduledTaskTrigger -Daily -At 2am
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "Rebuild Docs Search Index"
```

## Index Statistics

Current index (as of last build):
- **Documents Indexed**: 55
- **Index Size**: ~264 KB
- **Directories Scanned**: TL2, TL2_dotnet, TLCloud, Generated

## Troubleshooting

### Search Not Working

1. Verify `search-index.json` exists in the root directory
2. Check browser console for errors
3. Rebuild the index: `.\build-search-index.ps1`

### Outdated Results

The index is pre-built, so new or modified documents won't appear until you rebuild:

```powershell
.\build-search-index.ps1
```

Then refresh the browser.

### Performance

- **55 documents**: Index loads in ~100ms
- **500+ documents**: Still fast, ~500ms load time
- **1000+ documents**: Consider splitting into multiple indices

## Technical Details

### Search Index Format

```json
{
    "metadata": {
        "buildDate": "2026-02-02T...",
        "totalDocuments": 55,
        "version": "1.0"
    },
    "documents": [
        {
            "id": 1,
            "title": "Document Title",
            "path": "TLCloud/Architecture/...",
            "category": "TLCloud",
            "summary": "First paragraph...",
            "headings": "Heading1 Heading2...",
            "content": "Cleaned full text...",
            "size": 12345,
            "modified": "2026-02-02T..."
        }
    ]
}
```

### Lunr.js Configuration

- **Fields**: title (10x), headings (5x), summary (3x), category (2x), content (1x)
- **Stemming**: Enabled (English)
- **Stop words**: Removed automatically
- **Fuzzy matching**: Supported with `~` suffix (e.g., `licens~`)

### Performance Optimization

The pre-built approach provides:
- **Zero parse time**: Documents already processed
- **Instant startup**: No document fetching on page load
- **Consistent results**: Same index for all users
- **Offline capable**: Works without network access
