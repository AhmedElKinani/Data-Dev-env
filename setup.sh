#!/usr/bin/env bash
# =============================================================================
# setup.sh — Data-stack-dev-env bootstrap script
#
# What this script does:
#   1. Creates required local directories
#   2. Starts all Docker Compose services
#   3. Initialises Apache Superset (DB migrations + admin user)
#   4. Prints service URLs
# =============================================================================

set -euo pipefail

# ── Colours ──────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Colour

log()  { echo -e "${CYAN}[setup]${NC} $*"; }
ok()   { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[✗]${NC} $*"; exit 1; }

# ── Step 1: Directory scaffold ─────────────────────────────────────────────────
log "Creating project directories..."
mkdir -p data/raw data/gold data/predictions models sql/init notebooks
ok "Directories ready."

# ── Step 2: Start Docker Compose services ─────────────────────────────────────
log "Starting Docker Compose services..."
docker compose up -d

log "Waiting for PostgreSQL to become healthy..."
RETRIES=30
COUNT=0
until docker compose exec postgres pg_isready -U postgres -q 2>/dev/null; do
    COUNT=$((COUNT + 1))
    if [ $COUNT -ge $RETRIES ]; then
        err "PostgreSQL did not become healthy in time. Check: docker compose logs postgres"
    fi
    echo -n "."
    sleep 3
done
echo ""
ok "PostgreSQL is healthy."

log "Waiting for Superset to start (this may take ~60 seconds)..."
RETRIES=40
COUNT=0
until docker compose exec superset curl -sf http://localhost:8088/health > /dev/null 2>&1; do
    COUNT=$((COUNT + 1))
    if [ $COUNT -ge $RETRIES ]; then
        warn "Superset not responding yet — you may need to run Superset init manually."
        warn "See README.md → Manual Superset Init."
        break
    fi
    echo -n "."
    sleep 5
done
echo ""

# ── Step 3: Superset initialisation ───────────────────────────────────────────
log "Initialising Superset (DB migrations, admin user, roles)..."

# Source env vars for admin credentials
set -a; source .env; set +a

docker compose exec superset superset db upgrade || warn "Superset db upgrade may have already run."

docker compose exec superset superset fab create-admin \
    --username  "${SUPERSET_ADMIN_USER}" \
    --firstname "${SUPERSET_ADMIN_FIRSTNAME:-Admin}" \
    --lastname  "${SUPERSET_ADMIN_LASTNAME:-User}" \
    --email     "${SUPERSET_ADMIN_EMAIL}" \
    --password  "${SUPERSET_ADMIN_PASSWORD}" \
    2>/dev/null || warn "Admin user may already exist — skipping."

docker compose exec superset superset init || warn "Superset init may have already run."

ok "Superset initialised."

# ── Done ────────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Data-stack-dev-env is ready!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${CYAN}Jupyter Lab${NC}   →  http://localhost:8888"
echo -e "  ${CYAN}ClearML UI${NC}    →  http://localhost:8080"
echo -e "  ${CYAN}Superset${NC}      →  http://localhost:8088  (admin / admin)"
echo -e "  ${CYAN}PostgreSQL${NC}    →  localhost:5432  (postgres / postgres)"
echo ""
echo -e "  ${YELLOW}Next steps:${NC}"
echo -e "  1. Open Jupyter → run notebooks/spark_clearml_playbook.ipynb"
echo -e "  2. Open ClearML → verify logged metrics & artifacts"
echo -e "  3. Open Superset → connect to postgres database"
echo ""
echo -e "  ${YELLOW}Check service health:${NC}  docker compose ps"
echo -e "  ${YELLOW}View logs:${NC}             docker compose logs -f <service>"
echo -e "  ${YELLOW}Stop all:${NC}              docker compose down"
echo ""
