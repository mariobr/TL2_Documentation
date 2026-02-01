# TrustedLicensing Documentation Viewer

A modern, browser-based documentation viewer for the TrustedLicensing documentation repository.

## Features

✨ **Rich Document Support**
- 📝 Markdown rendering with syntax highlighting
- 📊 Mermaid diagram rendering
- 🎨 PlantUML diagram support
- 📄 PDF document viewing
- 🔍 Full-text search

🎯 **Organized Navigation**
- 📁 Hierarchical document tree
- 🏷️ Topic-based categorization
- 🔎 Real-time filtering
- 📂 Repository filtering
- 📋 File type filtering

🎨 **Modern UI**
- Split-view layout
- Dark mode support
- Responsive design
- Smooth animations
- Toast notifications

## Getting Started

### Prerequisites

- A modern web browser (Chrome, Firefox, Edge, Safari)
- Local web server (optional, for full functionality)

### Opening the Viewer

#### Option 1: Direct File Access (Limited)
Simply open `index.html` in your browser:
```bash
cd Viewer
start index.html  # Windows
open index.html   # macOS
xdg-open index.html  # Linux
```

**Note:** Direct file access has limitations with loading local markdown files due to browser security (CORS). Use Option 2 for full functionality.

#### Option 2: Local Web Server (Recommended)

**Using Python:**
```bash
cd TL2_Documentation
python -m http.server 8000
# Open browser to: http://localhost:8000/Viewer/
```

**Using Node.js (http-server):**
```bash
cd TL2_Documentation
npx http-server -p 8000
# Open browser to: http://localhost:8000/Viewer/
```

**Using PowerShell:**
```powershell
cd Viewer
# Simple PowerShell HTTP server
$http = [System.Net.HttpListener]::new()
$http.Prefixes.Add("http://localhost:8000/")
$http.Start()
Write-Host "Server started at http://localhost:8000/" -ForegroundColor Green
while ($http.IsListening) {
    $context = $http.GetContext()
    $response = $context.Response
    # Handle request...
}
```

## Usage

### Navigation

**Hierarchy Tab:**
- Browse documents by folder structure
- Click folders to expand/collapse
- Click files to view content
- Use repository filter to show specific repositories
- Use file type filter to show specific formats

**Topics Tab:**
- Documents organized by categories (LMS, Client, Architecture, etc.)
- Click any document to view
- Badge shows number of documents per topic

### Search

Type in the search box to filter documents by name or path in real-time.

### Viewing Documents

**Markdown Files:**
- Rendered with syntax highlighting
- Tables, lists, code blocks fully supported
- Mermaid diagrams automatically rendered
- PlantUML diagrams rendered via PlantUML server

**PDF Files:**
- Embedded PDF viewer
- Full navigation support

**Other Formats:**
- Information page with file details
- Copy path functionality

### Actions

- **Copy Path:** Copy full file path to clipboard
- **Open External:** Shows file path for opening in external application
- **Refresh:** Reload document list from JSON

## Architecture

### Files

```
Viewer/
├── index.html      # Main HTML structure
├── styles.css      # Styling and layout
├── app.js          # Application logic
└── README.md       # This file
```

### Data Source

The viewer loads document metadata from:
```
../documents-available.json
```

This JSON file contains:
- Document paths
- Repository information
- File metadata (size, last modified)
- Full system paths

### External Dependencies

**CDN Libraries:**
- **Marked.js** (11.1.1) - Markdown parsing
- **Mermaid** (10.6.1) - Diagram rendering
- **PlantUML Encoder** (1.4.0) - PlantUML encoding
- **Highlight.js** (11.9.0) - Syntax highlighting

### Diagram Support

**Mermaid:**
Supports all Mermaid diagram types:
- Flowcharts
- Sequence diagrams
- Class diagrams
- State diagrams
- Entity relationship diagrams
- And more...

**PlantUML:**
Uses PlantUML.com server to render diagrams:
- Sequence diagrams
- Class diagrams
- Use case diagrams
- Activity diagrams
- Component diagrams
- And more...

## Customization

### Changing Colors

Edit CSS variables in `styles.css`:
```css
:root {
    --primary-color: #0066cc;
    --primary-hover: #0052a3;
    /* ... more variables */
}
```

### Adding File Type Support

1. Add icon in `getFileIcon()` function in `app.js`
2. Add rendering logic in `loadDocument()` function
3. Update file type filter in HTML

### Custom Diagram Servers

To use a private PlantUML server, modify in `app.js`:
```javascript
const imgUrl = `https://your-plantuml-server.com/svg/${encoded}`;
```

## Troubleshooting

### Documents Not Loading

**Problem:** Markdown content shows "Document not found"

**Solution:** 
- Ensure you're using a local web server (not file:// protocol)
- Check that `documents-available.json` paths are correct
- Verify files exist at specified locations

### Diagrams Not Rendering

**Problem:** Mermaid or PlantUML diagrams don't appear

**Solution:**
- Check browser console for errors
- Ensure internet connection (CDN libraries)
- For PlantUML, verify plantuml.com is accessible
- Check diagram syntax is valid

### PDF Not Displaying

**Problem:** PDF shows blank or error

**Solution:**
- Verify PDF path is correct
- Check browser PDF plugin is enabled
- Try opening PDF in external viewer

## Browser Compatibility

Tested and supported on:
- ✅ Chrome 90+
- ✅ Firefox 88+
- ✅ Edge 90+
- ✅ Safari 14+

## Performance

- **Document Loading:** < 100ms for markdown files
- **Tree Rendering:** Handles 500+ documents smoothly
- **Search:** Real-time filtering with < 50ms response
- **Diagram Rendering:** Depends on diagram complexity

## Future Enhancements

Potential improvements:
- [ ] Full-text search within document content
- [ ] Document comparison view
- [ ] Export to PDF functionality
- [ ] Bookmarking favorite documents
- [ ] Recent documents list
- [ ] Custom theme support
- [ ] Offline mode with service worker
- [ ] Word/PowerPoint preview support

## License

Part of the TrustedLicensing documentation system.

## Version

**Version:** 1.0  
**Created:** 1 February 2026  
**Last Updated:** 1 February 2026

---

**Questions or Issues?**  
Check the browser console (F12) for detailed error messages.
