// TrustedLicensing Documentation Viewer
// Main Application JavaScript

// Global state
const state = {
    documents: {},
    currentDocument: null,
    filteredDocs: [],
    topics: {},
    searchTerm: '',
    filters: {
        repository: 'all',
        fileType: 'all'
    }
};

// Initialize application
document.addEventListener('DOMContentLoaded', async () => {
    console.log('Initializing Documentation Viewer...');
    
    // Load theme preference
    loadThemePreference();
    
    // Initialize Mermaid
    updateMermaidTheme();
    
    // Configure marked for markdown rendering
    marked.setOptions({
        highlight: function(code, lang) {
            if (lang && hljs.getLanguage(lang)) {
                return hljs.highlight(code, { language: lang }).value;
            }
            return hljs.highlightAuto(code).value;
        },
        breaks: true,
        gfm: true
    });
    
    // Load documents
    await loadDocuments();
    
    // Setup event listeners
    setupEventListeners();
    
    // Initialize UI
    initializeUI();
});

// Load documents from JSON and Generated folder
async function loadDocuments() {
    try {
        showLoading(true);
        
        // Load documents from JSON file
        const jsonResponse = await fetch('../documents-available.json');
        if (!jsonResponse.ok) {
            throw new Error(`Failed to load documents: ${jsonResponse.statusText}`);
        }
        state.documents = await jsonResponse.json();
        
        console.log(`Loaded ${Object.keys(state.documents).length} documents from JSON`);
        
        // Load documents from Generated folder
        try {
            const generatedResponse = await fetch('/api/generated-docs');
            if (generatedResponse.ok) {
                const generatedDocs = await generatedResponse.json();
                
                // Merge Generated folder documents
                Object.assign(state.documents, generatedDocs);
                
                console.log(`Loaded ${Object.keys(generatedDocs).length} documents from Generated folder`);
            }
        } catch (error) {
            console.warn('Could not load Generated folder documents:', error);
        }
        
        state.filteredDocs = Object.keys(state.documents);
        console.log(`Total documents: ${state.filteredDocs.length}`);
        
        // Extract topics from documents
        extractTopics();
        
        showLoading(false);
    } catch (error) {
        console.error('Error loading documents:', error);
        showError('Failed to load documents. Please ensure documents-available.json exists.');
        showLoading(false);
    }
}

// Extract topics from document paths
function extractTopics() {
    state.topics = {};
    
    Object.entries(state.documents).forEach(([path, doc]) => {
        const parts = path.split('/');
        const repo = doc.repository;
        
        // Extract folder-based topics
        if (parts.length > 2) {
            const topic = parts[1]; // e.g., "LMS", "Client", "Architecture"
            
            if (!state.topics[topic]) {
                state.topics[topic] = [];
            }
            
            state.topics[topic].push({
                path: path,
                name: parts[parts.length - 1],
                doc: doc
            });
        }
    });
    
    console.log('Extracted topics:', Object.keys(state.topics));
}

// Setup event listeners
function setupEventListeners() {
    // Tab switching
    document.querySelectorAll('.tab-button').forEach(button => {
        button.addEventListener('click', () => switchTab(button.dataset.tab));
    });
    
    // Search input
    const searchInput = document.getElementById('searchInput');
    searchInput.addEventListener('input', (e) => {
        state.searchTerm = e.target.value.toLowerCase();
        applyFilters();
    });
    
    // Filters
    document.getElementById('repositoryFilter').addEventListener('change', (e) => {
        state.filters.repository = e.target.value;
        applyFilters();
    });
    
    document.getElementById('fileTypeFilter').addEventListener('change', (e) => {
        state.filters.fileType = e.target.value;
        applyFilters();
    });
    
    // Refresh button
    document.getElementById('refreshBtn').addEventListener('click', async () => {
        await loadDocuments();
        initializeUI();
        showSuccess('Documents refreshed successfully');
    });
    
    // Open external button
    document.getElementById('openExternalBtn').addEventListener('click', () => {
        if (state.currentDocument) {
            const doc = state.documents[state.currentDocument];
            showSuccess(`Path: ${doc.fullPath}`);
        }
    });
    
    // Copy path button
    document.getElementById('copyPathBtn').addEventListener('click', () => {
        if (state.currentDocument) {
            const doc = state.documents[state.currentDocument];
            copyToClipboard(doc.fullPath);
        }
    });
    
    // Theme toggle button
    document.getElementById('themeToggle').addEventListener('click', toggleTheme);
}

// Initialize UI components
function initializeUI() {
    populateRepositoryFilter();
    renderDocumentTree();
    renderTopics();
}

// Populate repository filter
function populateRepositoryFilter() {
    const repositories = new Set();
    Object.values(state.documents).forEach(doc => {
        repositories.add(doc.repository);
    });
    
    const filter = document.getElementById('repositoryFilter');
    const currentValue = filter.value;
    
    // Keep "All Repositories" option
    filter.innerHTML = '<option value="all">All Repositories</option>';
    
    Array.from(repositories).sort().forEach(repo => {
        const option = document.createElement('option');
        option.value = repo;
        option.textContent = repo;
        filter.appendChild(option);
    });
    
    filter.value = currentValue;
}

// Apply filters to document list
function applyFilters() {
    state.filteredDocs = Object.keys(state.documents).filter(path => {
        const doc = state.documents[path];
        
        // Repository filter
        if (state.filters.repository !== 'all' && doc.repository !== state.filters.repository) {
            return false;
        }
        
        // File type filter
        if (state.filters.fileType !== 'all') {
            const extensions = state.filters.fileType.split(',');
            const hasExtension = extensions.some(ext => path.toLowerCase().endsWith(ext));
            if (!hasExtension) return false;
        }
        
        // Search filter
        if (state.searchTerm && !path.toLowerCase().includes(state.searchTerm)) {
            return false;
        }
        
        return true;
    });
    
    renderDocumentTree();
}

// Switch between tabs
function switchTab(tabName) {
    // Update tab buttons
    document.querySelectorAll('.tab-button').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.tab === tabName);
    });
    
    // Update tab content
    document.querySelectorAll('.tab-content').forEach(content => {
        content.classList.toggle('active', content.id === `${tabName}Tab`);
    });
}

// Render document tree with hierarchy
function renderDocumentTree() {
    const treeContainer = document.getElementById('documentTree');
    const tree = buildTree(state.filteredDocs);
    treeContainer.innerHTML = renderTree(tree);
    
    // Add click handlers
    treeContainer.querySelectorAll('.tree-item').forEach(item => {
        item.addEventListener('click', (e) => {
            e.stopPropagation();
            
            if (item.classList.contains('folder')) {
                toggleFolder(item);
            } else {
                const path = item.dataset.path;
                if (path) {
                    loadDocument(path);
                }
            }
        });
    });
}

// Build hierarchical tree structure
function buildTree(paths) {
    const tree = {};
    
    paths.forEach(path => {
        const parts = path.split('/');
        let current = tree;
        
        parts.forEach((part, index) => {
            if (!current[part]) {
                current[part] = {
                    name: part,
                    isFolder: index < parts.length - 1,
                    path: parts.slice(0, index + 1).join('/'),
                    children: {}
                };
            }
            current = current[part].children;
        });
    });
    
    return tree;
}

// Render tree as HTML
function renderTree(tree, level = 0) {
    let html = '';
    
    const sortedKeys = Object.keys(tree).sort((a, b) => {
        const aIsFolder = tree[a].isFolder;
        const bIsFolder = tree[b].isFolder;
        
        if (aIsFolder && !bIsFolder) return -1;
        if (!aIsFolder && bIsFolder) return 1;
        return a.localeCompare(b);
    });
    
    sortedKeys.forEach(key => {
        const node = tree[key];
        const icon = node.isFolder ? '📁' : getFileIcon(node.name);
        const itemClass = node.isFolder ? 'tree-item folder' : 'tree-item file';
        const dataPath = node.isFolder ? '' : `data-path="${node.path}"`;
        
        html += `
            <div class="tree-node">
                <div class="${itemClass}" ${dataPath}>
                    <span class="tree-icon">${icon}</span>
                    <span class="tree-label">${node.name}</span>
                </div>
        `;
        
        if (node.isFolder && Object.keys(node.children).length > 0) {
            html += `<div class="tree-children">${renderTree(node.children, level + 1)}</div>`;
        }
        
        html += '</div>';
    });
    
    return html;
}

// Get file icon based on extension
function getFileIcon(filename) {
    const ext = filename.split('.').pop().toLowerCase();
    const icons = {
        'md': '📝',
        'pdf': '📄',
        'docx': '📘',
        'doc': '📘',
        'ppt': '📊',
        'pptx': '📊',
        'html': '🌐',
        'json': '📋',
        'xml': '📋',
        'txt': '📃',
        'drawio': '🎨'
    };
    return icons[ext] || '📄';
}

// Toggle folder open/close
function toggleFolder(folderItem) {
    const children = folderItem.parentElement.querySelector('.tree-children');
    if (children) {
        children.classList.toggle('collapsed');
        const icon = folderItem.querySelector('.tree-icon');
        icon.textContent = children.classList.contains('collapsed') ? '📁' : '📂';
    }
}

// Render topics view
function renderTopics() {
    const container = document.getElementById('topicsContainer');
    let html = '';
    
    const sortedTopics = Object.keys(state.topics).sort();
    
    sortedTopics.forEach(topic => {
        const docs = state.topics[topic];
        html += `
            <div class="topic-group">
                <div class="topic-header">
                    ${topic}
                    <span class="doc-count">${docs.length}</span>
                </div>
        `;
        
        docs.forEach(item => {
            html += `
                <div class="topic-item" data-path="${item.path}">
                    ${getFileIcon(item.name)} ${item.name}
                </div>
            `;
        });
        
        html += '</div>';
    });
    
    container.innerHTML = html;
    
    // Add click handlers
    container.querySelectorAll('.topic-item').forEach(item => {
        item.addEventListener('click', () => {
            const path = item.dataset.path;
            loadDocument(path);
        });
    });
}

// Load and display document
async function loadDocument(path) {
    const doc = state.documents[path];
    if (!doc) {
        showError('Document not found');
        return;
    }
    
    state.currentDocument = path;
    
    // Update selection in tree
    document.querySelectorAll('.tree-item').forEach(item => {
        item.classList.toggle('selected', item.dataset.path === path);
    });
    
    // Update breadcrumb
    updateBreadcrumb(path);
    
    // Show toolbar buttons
    document.getElementById('openExternalBtn').style.display = 'block';
    document.getElementById('copyPathBtn').style.display = 'block';
    
    // Load content based on file type
    const ext = path.split('.').pop().toLowerCase();
    
    showLoading(true);
    
    try {
        if (ext === 'md') {
            await loadMarkdownDocument(doc);
        } else if (ext === 'pdf') {
            loadPdfDocument(doc);
        } else if (['docx', 'doc', 'ppt', 'pptx'].includes(ext)) {
            showUnsupportedFormat(ext);
        } else {
            showUnsupportedFormat(ext);
        }
    } catch (error) {
        console.error('Error loading document:', error);
        showError(`Failed to load document: ${error.message}`);
    } finally {
        showLoading(false);
    }
}

// Load markdown document
async function loadMarkdownDocument(doc) {
    try {
        // Try to load from workspace path
        const possiblePaths = [
            `../${doc.workspaceRelativePath}`,
            doc.workspaceRelativePath,
            doc.relativePath
        ];
        
        let content = null;
        let error = null;
        
        for (const path of possiblePaths) {
            try {
                const response = await fetch(path);
                if (response.ok) {
                    content = await response.text();
                    break;
                }
            } catch (e) {
                error = e;
            }
        }
        
        if (!content) {
            throw new Error('Could not load document from any path');
        }
        
        // Process markdown content
        await renderMarkdown(content);
        
    } catch (error) {
        console.error('Error loading markdown:', error);
        showDocumentInfo(doc);
    }
}

// Render markdown content with Mermaid and PlantUML support
async function renderMarkdown(markdown) {
    const viewer = document.getElementById('viewerContent');
    
    // Extract and process mermaid diagrams
    let processedMarkdown = markdown;
    const mermaidBlocks = [];
    
    // Extract mermaid code blocks
    processedMarkdown = processedMarkdown.replace(/```mermaid\n([\s\S]*?)```/g, (match, code) => {
        const id = `mermaid-${mermaidBlocks.length}`;
        mermaidBlocks.push({ id, code: code.trim() });
        return `<div class="mermaid-placeholder" data-id="${id}"></div>`;
    });
    
    // Extract plantuml code blocks
    const plantumlBlocks = [];
    processedMarkdown = processedMarkdown.replace(/```plantuml\n([\s\S]*?)```/g, (match, code) => {
        const id = `plantuml-${plantumlBlocks.length}`;
        plantumlBlocks.push({ id, code: code.trim() });
        return `<div class="plantuml-placeholder" data-id="${id}"></div>`;
    });
    
    // Convert markdown to HTML
    const html = marked.parse(processedMarkdown);
    
    viewer.innerHTML = `<div class="markdown-content">${html}</div>`;
    
    // Highlight code blocks
    viewer.querySelectorAll('pre code').forEach(block => {
        hljs.highlightElement(block);
    });
    
    // Render mermaid diagrams
    for (const block of mermaidBlocks) {
        try {
            const placeholder = viewer.querySelector(`[data-id="${block.id}"]`);
            if (placeholder) {
                const { svg } = await mermaid.render(block.id, block.code);
                placeholder.innerHTML = svg;
                placeholder.classList.add('mermaid');
            }
        } catch (error) {
            console.error('Error rendering mermaid diagram:', error);
        }
    }
    
    // Render PlantUML diagrams
    for (const block of plantumlBlocks) {
        try {
            const placeholder = viewer.querySelector(`[data-id="${block.id}"]`);
            if (placeholder) {
                const encoded = plantumlEncoder.encode(block.code);
                const imgUrl = `https://www.plantuml.com/plantuml/svg/${encoded}`;
                placeholder.innerHTML = `
                    <div class="plantuml-diagram">
                        <img src="${imgUrl}" alt="PlantUML Diagram" />
                    </div>
                `;
            }
        } catch (error) {
            console.error('Error rendering PlantUML diagram:', error);
        }
    }
}

// Load PDF document
function loadPdfDocument(doc) {
    const viewer = document.getElementById('viewerContent');
    
    // Try multiple path strategies
    const possiblePaths = [
        `/${doc.workspaceRelativePath}`,
        `../${doc.workspaceRelativePath}`,
        doc.workspaceRelativePath
    ];
    
    // Use the first path and add error handling
    const pdfPath = possiblePaths[0];
    
    viewer.innerHTML = `
        <div style="width: 100%; height: calc(100vh - ${document.querySelector('.viewer-toolbar').offsetHeight + 48}px); display: flex; flex-direction: column;">
            <iframe 
                class="pdf-viewer" 
                src="${pdfPath}" 
                style="width: 100%; height: 100%; border: none;"
                onerror="console.error('PDF load error')"
            ></iframe>
        </div>
    `;
    
    // Check if PDF loads successfully
    const iframe = viewer.querySelector('iframe');
    iframe.addEventListener('error', () => {
        showError('Failed to load PDF. File may not be accessible.');
        showDocumentInfo(doc);
    });
}

// Show unsupported format message
function showUnsupportedFormat(ext) {
    const viewer = document.getElementById('viewerContent');
    const doc = state.documents[state.currentDocument];
    
    viewer.innerHTML = `
        <div class="welcome-screen">
            <div class="welcome-icon">⚠️</div>
            <h2>Unsupported Format</h2>
            <p>Cannot display .${ext} files in the browser</p>
            <div style="margin-top: 20px;">
                <button class="btn btn-primary" onclick="copyToClipboard('${doc.fullPath}')">
                    📋 Copy File Path
                </button>
            </div>
            <div style="margin-top: 20px; color: var(--text-secondary); font-size: 14px;">
                <strong>File Path:</strong><br>
                <code>${doc.fullPath}</code>
            </div>
        </div>
    `;
}

// Show document info when content can't be loaded
function showDocumentInfo(doc) {
    const viewer = document.getElementById('viewerContent');
    
    const sizeKB = (doc.size / 1024).toFixed(2);
    
    viewer.innerHTML = `
        <div class="markdown-content">
            <h1>📄 Document Information</h1>
            <p><strong>Note:</strong> Document content could not be loaded from the file system. This viewer can only display documents that are accessible via relative paths.</p>
            
            <h2>File Details</h2>
            <table>
                <tr>
                    <th>Property</th>
                    <th>Value</th>
                </tr>
                <tr>
                    <td>Repository</td>
                    <td>${doc.repository}</td>
                </tr>
                <tr>
                    <td>Relative Path</td>
                    <td><code>${doc.relativePath}</code></td>
                </tr>
                <tr>
                    <td>Full Path</td>
                    <td><code>${doc.fullPath}</code></td>
                </tr>
                <tr>
                    <td>Size</td>
                    <td>${sizeKB} KB</td>
                </tr>
                <tr>
                    <td>Last Modified</td>
                    <td>${doc.lastModified}</td>
                </tr>
            </table>
            
            <h2>Actions</h2>
            <button class="btn btn-primary" onclick="copyToClipboard('${doc.fullPath}')">
                📋 Copy Full Path
            </button>
        </div>
    `;
}

// Update breadcrumb
function updateBreadcrumb(path) {
    const breadcrumb = document.getElementById('breadcrumb');
    const parts = path.split('/');
    
    let html = '<span class="breadcrumb-home">📚</span>';
    
    parts.forEach((part, index) => {
        if (index > 0) {
            html += '<span class="breadcrumb-separator">›</span>';
        }
        html += `<span>${part}</span>`;
    });
    
    breadcrumb.innerHTML = html;
}

// Show/hide loading indicator
function showLoading(show) {
    document.getElementById('loadingIndicator').style.display = show ? 'flex' : 'none';
    if (!show) {
        document.querySelector('.welcome-screen')?.remove();
    }
}

// Show error toast
function showError(message) {
    const toast = document.getElementById('errorToast');
    const messageEl = document.getElementById('errorMessage');
    
    messageEl.textContent = message;
    toast.style.display = 'flex';
    
    setTimeout(() => {
        toast.style.display = 'none';
    }, 5000);
}

// Show success toast
function showSuccess(message) {
    const toast = document.getElementById('successToast');
    const messageEl = document.getElementById('successMessage');
    
    messageEl.textContent = message;
    toast.style.display = 'flex';
    
    setTimeout(() => {
        toast.style.display = 'none';
    }, 3000);
}

// Hide toast
function hideToast() {
    document.getElementById('errorToast').style.display = 'none';
    document.getElementById('successToast').style.display = 'none';
}

// Copy text to clipboard
function copyToClipboard(text) {
    if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(text).then(() => {
            showSuccess('Path copied to clipboard');
        }).catch(err => {
            showError('Failed to copy to clipboard');
        });
    } else {
        // Fallback for older browsers
        const textarea = document.createElement('textarea');
        textarea.value = text;
        textarea.style.position = 'fixed';
        textarea.style.opacity = '0';
        document.body.appendChild(textarea);
        textarea.select();
        try {
            document.execCommand('copy');
            showSuccess('Path copied to clipboard');
        } catch (err) {
            showError('Failed to copy to clipboard');
        }
        document.body.removeChild(textarea);
    }
}

// Theme management
function loadThemePreference() {
    const savedTheme = localStorage.getItem('docs-viewer-theme') || 'light';
    if (savedTheme === 'dark') {
        document.documentElement.classList.add('dark-theme');
        updateThemeIcon('dark');
    } else {
        updateThemeIcon('light');
    }
}

function toggleTheme() {
    const isDark = document.documentElement.classList.toggle('dark-theme');
    const theme = isDark ? 'dark' : 'light';
    localStorage.setItem('docs-viewer-theme', theme);
    updateThemeIcon(theme);
    updateMermaidTheme();
    showSuccess(`Switched to ${theme} mode`);
}

function updateThemeIcon(theme) {
    const icon = document.querySelector('.theme-icon');
    if (icon) {
        icon.textContent = theme === 'dark' ? '☀️' : '🌙';
    }
}

function updateMermaidTheme() {
    const isDark = document.documentElement.classList.contains('dark-theme');
    mermaid.initialize({ 
        startOnLoad: false,
        theme: isDark ? 'dark' : 'default',
        securityLevel: 'loose',
        flowchart: { useMaxWidth: true }
    });
}
