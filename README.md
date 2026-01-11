# TeamSync Editor

A production-ready, collaborative office editing platform with three specialized editors optimized for cloud deployment. Built on Collabora Online, TeamSync delivers lightweight, fast-loading document editing in the browser.

<p align="center">
  <img src="docker/branding/images/teamsync-logo.svg" alt="TeamSync Logo" width="200">
</p>

## Product Suite

TeamSync Editor consists of three separately branded, optimized products:

| Product | Description | Supported Formats |
|---------|-------------|-------------------|
| **TeamSync Document** | Word processing editor | `.docx`, `.doc`, `.odt`, `.rtf`, `.txt` |
| **TeamSync Sheets** | Spreadsheet editor | `.xlsx`, `.xls`, `.ods`, `.csv` |
| **TeamSync Presentation** | Presentation editor | `.pptx`, `.ppt`, `.odp` |

Each product is packaged as an independent Docker image containing only the LibreOffice components it needs, resulting in smaller images (~800 MB each) and faster startup times.

## Features

- **Real-time Collaboration** - Multiple users can edit the same document simultaneously
- **WOPI Protocol** - Industry-standard integration protocol for document editing
- **Cloud-Native** - Optimized for Kubernetes, Railway, and containerized environments
- **Lightweight Images** - Component-specific builds reduce image size by 60%+
- **Enterprise Security** - JWT authentication, HTTPS, and configurable access controls
- **S3 Storage** - Works with any S3-compatible storage (AWS S3, MinIO, etc.)

## Quick Start

### Using Pre-built Images (Recommended)

The fastest way to get started is with our pre-built Docker images from GitHub Container Registry:

```bash
# Pull the images
docker pull ghcr.io/angelbot-ai-pvt-ltd/teamsync-document:latest
docker pull ghcr.io/angelbot-ai-pvt-ltd/teamsync-sheets:latest
docker pull ghcr.io/angelbot-ai-pvt-ltd/teamsync-presentation:latest

# Run TeamSync Document
docker run -d \
  --name teamsync-document \
  -p 9980:9980 \
  -e "aliasgroup1=https://your-wopi-host.com:443" \
  ghcr.io/angelbot-ai-pvt-ltd/teamsync-document:latest
```

### Using Docker Compose

For a complete development setup with all three editors:

```bash
# Clone the repository
git clone https://github.com/angelbot-ai-pvt-ltd/teamsync-editor.git
cd teamsync-editor

# Copy environment template
cp .env.example .env

# Edit configuration
nano .env

# Start all services
docker compose -f docker-compose.multi.yml up -d
```

This starts:
- **TeamSync Document** on port `9980`
- **TeamSync Sheets** on port `9981`
- **TeamSync Presentation** on port `9982`
- **Sample WOPI App** on port `8080`

### Single Editor Setup

If you only need one editor type:

```bash
# Document editor only
docker compose -f docker-compose.document-only.yml up -d

# Or using the main compose file
docker compose up -d
```

## Architecture

```
┌─────────────────────────────────────────────────┐
│              Your Application                    │
│         (Web App, File Manager, etc.)           │
└─────────────────────────────────────────────────┘
                        │
                        ▼ WOPI Protocol
┌─────────────────────────────────────────────────┐
│           WOPI Host (Your Backend)              │
│    - Token generation & validation              │
│    - File storage integration                   │
│    - User permission management                 │
└─────────────────────────────────────────────────┘
                        │
        ┌───────────────┼───────────────┐
        ▼               ▼               ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│   TeamSync   │ │   TeamSync   │ │   TeamSync   │
│   Document   │ │    Sheets    │ │ Presentation │
│    :9980     │ │    :9981     │ │    :9982     │
└──────────────┘ └──────────────┘ └──────────────┘
```

## Using the Editor

### Embedding in Your Application

TeamSync editors are embedded via iframe using the WOPI protocol. Here's how to integrate:

#### 1. Generate a WOPI Access Token

Your backend generates a JWT token that grants access to a specific document:

```javascript
const jwt = require('jsonwebtoken');

function generateWopiToken(fileId, userId, permissions) {
  return jwt.sign(
    {
      fileId,
      userId,
      permissions, // 'view' or 'edit'
      exp: Math.floor(Date.now() / 1000) + 3600 // 1 hour
    },
    process.env.JWT_SECRET
  );
}
```

#### 2. Construct the Editor URL

```javascript
function getEditorUrl(fileId, accessToken) {
  const wopiSrc = encodeURIComponent(
    `https://your-wopi-host.com/wopi/files/${fileId}`
  );

  // Choose editor based on file type
  const editorHost = getEditorForFileType(fileId);

  return `${editorHost}/browser/dist/cool.html?WOPISrc=${wopiSrc}&access_token=${accessToken}`;
}

function getEditorForFileType(filename) {
  const ext = filename.split('.').pop().toLowerCase();

  if (['docx', 'doc', 'odt', 'rtf', 'txt'].includes(ext)) {
    return 'https://document.yourdomain.com';
  }
  if (['xlsx', 'xls', 'ods', 'csv'].includes(ext)) {
    return 'https://sheets.yourdomain.com';
  }
  if (['pptx', 'ppt', 'odp'].includes(ext)) {
    return 'https://presentation.yourdomain.com';
  }

  throw new Error(`Unsupported file type: ${ext}`);
}
```

#### 3. Embed the Editor

```html
<iframe
  id="teamsync-editor"
  src=""
  style="width: 100%; height: 100vh; border: none;"
  allow="fullscreen"
></iframe>

<script>
  async function openDocument(fileId) {
    // Get token from your backend
    const response = await fetch(`/api/documents/${fileId}/token`, {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${userToken}` }
    });

    const { editorUrl } = await response.json();
    document.getElementById('teamsync-editor').src = editorUrl;
  }
</script>
```

### WOPI Host Implementation

Your backend must implement these WOPI endpoints:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/wopi/files/:fileId` | GET | Return file metadata (CheckFileInfo) |
| `/wopi/files/:fileId/contents` | GET | Return file contents (GetFile) |
| `/wopi/files/:fileId/contents` | POST | Save file contents (PutFile) |

#### CheckFileInfo Response Example

```json
{
  "BaseFileName": "report.docx",
  "Size": 24576,
  "OwnerId": "user-123",
  "UserId": "user-456",
  "UserFriendlyName": "John Doe",
  "UserCanWrite": true,
  "UserCanNotWriteRelative": true,
  "PostMessageOrigin": "https://your-app.com",
  "LastModifiedTime": "2024-01-15T10:30:00Z"
}
```

See the [sample-app](./sample-app) directory for a complete Node.js WOPI host implementation.

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `aliasgroup1` | Allowed WOPI host URLs (required) | - |
| `server_name` | Server hostname for WOPI validation | `localhost` |
| `SSL_ENABLE` | Enable SSL (true/false) | `false` |
| `SSL_TERMINATION` | SSL handled by proxy (true/false) | `true` |
| `LOG_LEVEL` | Logging level | `warning` |
| `COOL_ADMIN_USER` | Admin console username | - |
| `COOL_ADMIN_PASSWORD` | Admin console password | - |
| `MEMPROPORTION` | Memory usage percentage | `80` |
| `MAX_DOCUMENTS` | Maximum concurrent documents | `100` |
| `MAX_CONNECTIONS` | Maximum concurrent connections | `200` |

### Allowing WOPI Hosts

Configure which hosts can use the editor by setting `aliasgroup1`:

```bash
# Single host
-e "aliasgroup1=https://app.example.com:443"

# Multiple hosts (comma-separated)
-e "aliasgroup1=https://app1.example.com:443,https://app2.example.com:443"

# With regex pattern
-e "aliasgroup1=https://.*\\.example\\.com:443"
```

### Admin Console

Access the admin console at `https://your-editor-host:9980/browser/dist/admin/admin.html`

Enable it by setting:
```bash
-e "COOL_ADMIN_USER=admin"
-e "COOL_ADMIN_PASSWORD=your-secure-password"
```

## Building from Source

### Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- 8GB+ RAM for building
- 50GB+ disk space

### Build Commands

```bash
# Build all variants
./docker/scripts/build.sh

# Build specific variant
./docker/scripts/build.sh document
./docker/scripts/build.sh sheets
./docker/scripts/build.sh presentation

# Build with custom tag
IMAGE_TAG=v1.0.0 ./docker/scripts/build.sh

# Build and push to registry
./docker/scripts/build.sh --push
```

### Build Options

| Dockerfile | Build Time | Description |
|------------|------------|-------------|
| `Dockerfile.*.prebuilt` | ~5 min | Uses pre-compiled artifacts (recommended) |
| `Dockerfile.*.25` | ~30 min | Builds from Collabora packages |
| `Dockerfile.*.optimized` | ~2 hours | Source build with optimizations |

## Deployment

### Railway

TeamSync is optimized for Railway deployment:

```bash
# Deploy using Railway CLI
railway up
```

The included `railway.toml` configures the deployment automatically.

### Kubernetes

Example deployment manifest:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: teamsync-document
spec:
  replicas: 2
  selector:
    matchLabels:
      app: teamsync-document
  template:
    metadata:
      labels:
        app: teamsync-document
    spec:
      containers:
      - name: teamsync-document
        image: ghcr.io/angelbot-ai-pvt-ltd/teamsync-document:latest
        ports:
        - containerPort: 9980
        env:
        - name: aliasgroup1
          value: "https://your-wopi-host.com:443"
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "2000m"
```

### Production Checklist

- [ ] Configure SSL termination (nginx, load balancer, or built-in)
- [ ] Set `aliasgroup1` to your WOPI host domains
- [ ] Use strong `JWT_SECRET` (32+ characters)
- [ ] Enable admin console only if needed
- [ ] Configure resource limits based on expected load
- [ ] Set up health check monitoring at `/hosting/discovery`
- [ ] Configure log aggregation for `LOG_LEVEL=warning` or higher

## Troubleshooting

### Editor Not Loading

```bash
# Check if the service is running
docker ps | grep teamsync

# View logs
docker logs teamsync-document

# Test WOPI discovery endpoint
curl http://localhost:9980/hosting/discovery
```

### WOPI Errors

Common issues:
- **Invalid token**: Ensure JWT secret matches between WOPI host and token generation
- **Host not allowed**: Add your WOPI host to `aliasgroup1`
- **CORS errors**: Configure `PostMessageOrigin` in CheckFileInfo response

### Document Not Saving

```bash
# Check WOPI host logs
docker logs your-wopi-host

# Verify PutFile endpoint returns 200 OK
# Check storage permissions
```

### Performance Issues

```bash
# Monitor resource usage
docker stats teamsync-document

# Adjust memory allocation
docker run -e "MEMPROPORTION=70" ...

# Limit concurrent documents
docker run -e "MAX_DOCUMENTS=50" ...
```

## Sample Application

The `sample-app` directory contains a complete WOPI host implementation for testing and reference:

```bash
cd sample-app
npm install
npm start
```

Open http://localhost:8080 to:
- Create sample documents (docx, xlsx, pptx)
- Upload your own files
- Test editing with all three editors

## License

- **TeamSync Editor Code**: Mozilla Public License 2.0
- **Collabora Online**: Mozilla Public License 2.0
- **LibreOffice Core**: Mozilla Public License 2.0

This project uses Collabora Online under MPL 2.0. Original MPL headers are preserved, and source code is available as required.

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting pull requests.

## Support

- **Issues**: [GitHub Issues](https://github.com/angelbot-ai-pvt-ltd/teamsync-editor/issues)
- **Documentation**: [Wiki](https://github.com/angelbot-ai-pvt-ltd/teamsync-editor/wiki)

---

<p align="center">
  Built with Collabora Online | Licensed under MPL 2.0
</p>
