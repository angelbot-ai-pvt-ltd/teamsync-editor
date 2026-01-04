# TeamSync Editor - Project Guidelines for Claude

## Product Branding

The TeamSync Editor suite consists of three separately branded products:

| Product | Docker Image | Description |
|---------|--------------|-------------|
| **TeamSync Document** | `teamsync-document` | Word processing editor |
| **TeamSync Sheets** | `teamsync-sheets` | Spreadsheet editor |
| **TeamSync Presentation** | `teamsync-presentation` | Presentation editor |

Each product should display its own branding in the UI, including product name, logo, and about dialog.

## Critical Constraints

### 1. NEVER Revert to Pre-built Collabora CODE Image
- TeamSync products MUST be built from Collabora Online source code
- Do NOT suggest using `collabora/code:latest` or any pre-built Collabora image as base
- The entire point of this project is to have custom-built, optimized editors
- Always work on fixing build issues rather than reverting to official images

### 2. Three Separate Optimized Docker Images
Build THREE separate, optimized Docker images - each containing ONLY the LibreOffice component it needs:

#### TeamSync Document (`docker/Dockerfile.document`)
- **Product Name**: TeamSync Document
- **Docker Image**: `teamsync-document`
- **LibreOffice Component**: Writer ONLY
- **Supported formats**: `.docx`, `.doc`, `.odt`, `.rtf`, `.txt`
- **Build flags**: `--disable-calc --disable-impress --disable-draw --disable-math --disable-base`
- **Target size**: Under 800 MB

#### TeamSync Sheets (`docker/Dockerfile.sheets`)
- **Product Name**: TeamSync Sheets
- **Docker Image**: `teamsync-sheets`
- **LibreOffice Component**: Calc ONLY
- **Supported formats**: `.xlsx`, `.xls`, `.ods`, `.csv`
- **Build flags**: `--disable-writer --disable-impress --disable-draw --disable-math --disable-base`
- **Target size**: Under 800 MB

#### TeamSync Presentation (`docker/Dockerfile.presentation`)
- **Product Name**: TeamSync Presentation
- **Docker Image**: `teamsync-presentation`
- **LibreOffice Component**: Impress ONLY
- **Supported formats**: `.pptx`, `.ppt`, `.odp`
- **Build flags**: `--disable-writer --disable-calc --disable-draw --disable-math --disable-base`
- **Target size**: Under 800 MB

### 3. Component-Specific Optimization

Each Dockerfile MUST:
- Build LibreOffice from source with appropriate `--disable-*` flags
- Include ONLY the runtime libraries needed for that component
- Remove all unused binaries, libraries, and assets after build
- Use multi-stage builds to minimize final image size

#### Libraries to Include Per Product

**TeamSync Document (Writer)**:
- `libswlo.so` - Writer core
- `libwpftwriterlo.so` - Word format filters
- Core shared libs only

**TeamSync Sheets (Calc)**:
- `libsclo.so` - Calc core
- `libscfiltlo.so` - Spreadsheet filters
- Core shared libs only

**TeamSync Presentation (Impress)**:
- `libsdlo.so` - Impress core
- `libsloideshow.so` - Slideshow engine
- Core shared libs only

### 4. Spell Checking
- Include English spell checking only (en_US, en_GB)
- Remove all other language dictionaries
- Each image gets its own minimal dictionary set

### 5. Docker Image Optimization Goals

| Product | Target Size | Performance Focus |
|---------|-------------|-------------------|
| TeamSync Document | < 800 MB | Fast document rendering, text processing |
| TeamSync Sheets | < 800 MB | Formula calculation, large dataset handling |
| TeamSync Presentation | < 800 MB | Slide rendering, media playback |

**Optimization techniques**:
- Multi-stage builds (build stage → minimal runtime stage)
- Remove: help docs, templates, galleries, wizards, samples
- Strip debug symbols from binaries
- Use `--no-install-recommends` for apt packages
- Clean apt cache and temp files in same layer

### 6. Build Approach

Each Dockerfile follows this pattern:
1. **Stage 1 (builder-base)**: Install build dependencies
2. **Stage 2 (locore)**: Build LibreOffice from source with component-specific flags
3. **Stage 3 (builder)**: Build Collabora Online (coolwsd) from source
4. **Stage 4 (runtime)**: Minimal Ubuntu base with only required runtime files

Build commands:
```bash
# Build individual images
docker build -f docker/Dockerfile.document -t teamsync-document .
docker build -f docker/Dockerfile.sheets -t teamsync-sheets .
docker build -f docker/Dockerfile.presentation -t teamsync-presentation .

# Or use build script
./docker/scripts/build.sh document
./docker/scripts/build.sh sheets
./docker/scripts/build.sh presentation
```

### 7. Runtime Configuration

Each product should have optimized runtime settings:

**TeamSync Document**:
- Memory limit: 512 MB per document
- Optimized for text reflow and pagination

**TeamSync Sheets**:
- Memory limit: 1 GB per spreadsheet (for large datasets)
- Optimized for formula recalculation

**TeamSync Presentation**:
- Memory limit: 768 MB per presentation
- Optimized for slide transitions and media

## Current Technical Challenges

### Jail/Namespace Issue
- coolforkit runs in a chroot jail and can't find libmergedlo.so
- The systemplate needs proper setup for LibreOffice access
- Solutions to explore:
  - Fix systemplate generation to include proper LO paths
  - Configure coolwsd to use different jail mode
  - Ensure bind mounts work correctly in Docker

### Key Files
- `docker/Dockerfile.document` - TeamSync Document build (Writer only)
- `docker/Dockerfile.sheets` - TeamSync Sheets build (Calc only)
- `docker/Dockerfile.presentation` - TeamSync Presentation build (Impress only)
- `docker/scripts/entrypoint.sh` - Container startup script
- `docker/scripts/build.sh` - Build script for all products
- `docker-compose.yml` - Development deployment config
- `docker-compose.multi.yml` - Multi-product deployment

## DO NOT
- Suggest using official Collabora CODE Docker image
- Remove the source-build approach
- Copy full LibreOffice installation - only copy component-specific files
- Share base images between variants (each must be independently optimized)
- Give up on optimization - find solutions instead
