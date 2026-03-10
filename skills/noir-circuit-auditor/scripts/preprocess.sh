#!/bin/bash
# Noir Circuit Auditor - Preprocessing Script
# Collects environment info, sources, and runs initial analysis

set -e

TARGET=${1:-.}
AUDIT_DIR="audit"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Noir Circuit Auditor - Preprocessing${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Pre-flight checks
if ! command -v nargo &> /dev/null; then
    echo -e "${RED}ERROR: nargo not found${NC}"
    echo "Install Noir: https://noir-lang.org/docs/getting_started/installation"
    exit 1
fi

# Resolve target
if [ ! -d "$TARGET" ]; then
    echo -e "${RED}ERROR: Directory not found: $TARGET${NC}"
    exit 1
fi

TARGET=$(cd "$TARGET" && pwd)

if [ ! -f "$TARGET/Nargo.toml" ]; then
    echo -e "${RED}ERROR: No Nargo.toml in $TARGET${NC}"
    echo "This doesn't appear to be a Noir project."
    exit 1
fi

echo -e "Target: ${GREEN}$TARGET${NC}"
echo ""

# Create audit directory
mkdir -p "$TARGET/$AUDIT_DIR"
cd "$TARGET"

# Step 1: Environment info
echo -e "${GREEN}[1/5]${NC} Collecting environment info..."
{
    echo "=== Environment ==="
    echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "Nargo: $(nargo --version 2>&1 | head -1)"
    echo "Target: $TARGET"
    echo ""
    echo "=== Nargo.toml ==="
    cat Nargo.toml
} > "$AUDIT_DIR/nargo_config.txt"

# Step 2: Check for workspace
echo -e "${GREEN}[2/5]${NC} Checking workspace structure..."
WORKSPACE_MEMBERS=""
if grep -q "\[workspace\]" Nargo.toml 2>/dev/null; then
    WORKSPACE_MEMBERS=$(grep -A 50 "\[workspace\]" Nargo.toml | grep "members" | head -1 || echo "")
    echo -e "  ${YELLOW}Workspace detected${NC}"
    echo "  Members: $WORKSPACE_MEMBERS"
fi

# Step 3: Run nargo check
echo -e "${GREEN}[3/5]${NC} Running static analysis (nargo check)..."
if nargo check 2>&1 | tee "$AUDIT_DIR/static.txt"; then
    echo -e "  ${GREEN}Static check passed${NC}"
else
    echo -e "  ${YELLOW}Warning: nargo check had issues (see static.txt)${NC}"
fi

# Step 4: Run tests
echo -e "${GREEN}[4/5]${NC} Running tests (nargo test)..."
{
    echo "=== Test Results ==="
    echo "Run at: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo ""
    nargo test 2>&1 || echo "Tests had failures or errors"
} | tee "$AUDIT_DIR/test_results.txt"

# Check for vulnerability tests
echo ""
if grep -qiE "vulnerability|exploit|attack|bug" "$AUDIT_DIR/test_results.txt" 2>/dev/null; then
    echo -e "  ${YELLOW}⚠ Potential vulnerability tests detected!${NC}"
    grep -iE "vulnerability|exploit|attack|bug" "$AUDIT_DIR/test_results.txt" | head -10
fi

# Step 5: Collect source files
echo -e "${GREEN}[5/5]${NC} Collecting source files..."
find . -name "*.nr" -type f | sed 's|^\./||' | sort > "$AUDIT_DIR/sources.txt"

FILE_COUNT=$(wc -l < "$AUDIT_DIR/sources.txt" | tr -d ' ')
TOTAL_LINES=0
while IFS= read -r file; do
    if [ -f "$file" ]; then
        LINES=$(wc -l < "$file" | tr -d ' ')
        TOTAL_LINES=$((TOTAL_LINES + LINES))
    fi
done < "$AUDIT_DIR/sources.txt"

# Summary
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Preprocessing complete${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "  Source files:    $FILE_COUNT"
echo "  Total lines:     $TOTAL_LINES"
echo "  Output:          $TARGET/$AUDIT_DIR/"
echo ""
echo "Files created:"
echo "  - audit/nargo_config.txt   # Nargo.toml + environment"
echo "  - audit/static.txt         # nargo check output"
echo "  - audit/test_results.txt   # nargo test output"
echo "  - audit/sources.txt        # .nr file inventory"
echo ""

# Warnings
if [ "$FILE_COUNT" -eq 0 ]; then
    echo -e "${RED}WARNING: No .nr files found!${NC}"
fi

if [ -n "$WORKSPACE_MEMBERS" ]; then
    echo -e "${YELLOW}NOTE: This is a workspace. Ensure ALL member packages are audited.${NC}"
fi

if grep -q "FAIL\|PASSED" "$AUDIT_DIR/test_results.txt" 2>/dev/null; then
    PASSED=$(grep -c "PASSED" "$AUDIT_DIR/test_results.txt" 2>/dev/null || echo 0)
    FAILED=$(grep -c "FAIL" "$AUDIT_DIR/test_results.txt" 2>/dev/null || echo 0)
    echo "Test summary: $PASSED passed, $FAILED failed"
fi

echo ""
echo "Ready for FINDER agent."
