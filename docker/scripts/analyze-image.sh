#!/bin/bash
# =============================================================================
# TeamSync Editor - Image Size Analyzer
# =============================================================================
#
# Usage: ./docker/scripts/analyze-image.sh [image-name]
#
# Examples:
#   ./docker/scripts/analyze-image.sh teamsync-document:latest
#   ./docker/scripts/analyze-image.sh teamsync-sheets:latest
#
# =============================================================================

set -e

IMAGE="${1:-teamsync-document:latest}"

echo "==========================================="
echo "Analyzing image: $IMAGE"
echo "==========================================="

# Check if image exists
if ! docker image inspect "$IMAGE" &>/dev/null; then
    echo "ERROR: Image '$IMAGE' not found"
    exit 1
fi

# Get total image size
echo ""
echo "Total image size:"
docker image inspect "$IMAGE" --format='{{.Size}}' | awk '{printf "  %.2f MB\n", $1/1024/1024}'

# Run container to analyze contents
echo ""
echo "Directory sizes:"
docker run --rm "$IMAGE" sh -c '
    echo "  /opt/cool:             $(du -sh /opt/cool 2>/dev/null | cut -f1)"
    echo "  /opt/cool/bin:         $(du -sh /opt/cool/bin 2>/dev/null | cut -f1)"
    echo "  /opt/cool/share:       $(du -sh /opt/cool/share 2>/dev/null | cut -f1)"
    echo "  /opt/cool/systemplate: $(du -sh /opt/cool/systemplate 2>/dev/null | cut -f1)"
    echo "  /opt/lokit:            $(du -sh /opt/lokit 2>/dev/null | cut -f1)"
    echo "  /opt/lokit/program:    $(du -sh /opt/lokit/program 2>/dev/null | cut -f1)"
    echo "  /opt/lokit/share:      $(du -sh /opt/lokit/share 2>/dev/null | cut -f1)"
'

echo ""
echo "Checking for LibreOffice duplication in systemplate:"
docker run --rm "$IMAGE" sh -c '
    if [ -d /opt/cool/systemplate/opt/lokit ]; then
        if [ -L /opt/cool/systemplate/opt/lokit ]; then
            echo "  OK: systemplate/opt/lokit is a symlink -> $(readlink /opt/cool/systemplate/opt/lokit)"
        else
            echo "  WARNING: LibreOffice DUPLICATED in systemplate!"
            echo "  Size: $(du -sh /opt/cool/systemplate/opt/lokit | cut -f1)"
            echo "  This is likely causing the image bloat!"
        fi
    elif [ -d /opt/cool/systemplate/opt ]; then
        echo "  OK: No lokit directory in systemplate/opt"
        ls -la /opt/cool/systemplate/opt/ 2>/dev/null || true
    else
        echo "  OK: No /opt/cool/systemplate/opt directory"
    fi
'

echo ""
echo "Top 15 largest files:"
docker run --rm "$IMAGE" sh -c '
    find /opt -type f -exec du -h {} \; 2>/dev/null | sort -rh | head -15
'

echo ""
echo "Shared library count:"
docker run --rm "$IMAGE" sh -c '
    echo "  /opt/lokit/program: $(find /opt/lokit/program -name "*.so*" -type f 2>/dev/null | wc -l) .so files"
    echo "  /opt/cool/systemplate: $(find /opt/cool/systemplate -name "*.so*" -type f 2>/dev/null | wc -l) .so files"
'

echo ""
echo "==========================================="
echo "Analysis complete"
echo "==========================================="
