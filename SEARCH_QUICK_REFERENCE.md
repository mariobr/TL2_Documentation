# 🔍 Search Quick Reference

## Build Index

```powershell
.\build-search-index.ps1          # Standard build
.\build-search-index.ps1 -Verbose # Show each file indexed
```

## Start Viewer

```powershell
.\start-viewer.ps1                # Build index + start viewer
.\Viewer\start-server.ps1         # Just start viewer
```

## Search Tips

| Query           | Finds                           |
|-----------------|----------------------------------|
| `TPM`           | Exact matches for "TPM"         |
| `license`       | Documents about licensing       |
| `crypto vault`  | Documents with both terms       |
| `TPM~`          | Fuzzy match (typos allowed)     |
| `+vault +crypto`| Must have both terms            |
| `-test`         | Exclude documents with "test"   |

## Index Stats

📊 **Current Index:**
- Documents: **55**
- Size: **264 KB**
- Categories: TLCloud (42), TL2 (7), Generated (5), TL2_dotnet (1)

⚡ **Performance:**
- Build: 2-3 seconds
- Load: ~100ms
- Search: <50ms

## When to Rebuild

🔄 Rebuild the index after:
- Adding new documents
- Editing existing documents
- Deleting documents
- Changing document structure

## Files

📁 **Key Files:**
- `build-search-index.ps1` - Index builder
- `search-index.json` - Generated index
- `SEARCH_SETUP.md` - Full documentation
- `SEARCH_IMPLEMENTATION.md` - Implementation details

## Troubleshooting

❌ **Search not working?**
1. Check `search-index.json` exists
2. Rebuild: `.\build-search-index.ps1`
3. Refresh browser

❌ **Old results?**
- Index is pre-built, rebuild to update

❌ **Missing documents?**
- Check document is in: TL2, TL2_dotnet, TLCloud, or Generated folders
- Rebuild index
