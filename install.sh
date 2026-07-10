#!/bin/bash
#
# install.sh — install every binary boringrecon depends on.
# Safe to re-run: skips anything already on PATH.
#
# Channels:
#   apt   -> system tools + wordlists   (nmap, jq, seclists, feroxbuster, python, go) maybe not
#   go    -> ProjectDiscovery & friends (httpx, katana, nuclei, subfinder, ffuf,
#                                         gowitness, assetfinder, subzy)
#   pipx  -> arjun
#
set -u

GREEN="\e[32m"; YELLOW="\e[33m"; RED="\e[31m"; BLUE="\e[34m"; RESET="\e[0m"
log()  { echo -e "${GREEN}[+]${RESET} $1"; }
warn() { echo -e "${YELLOW}[!]${RESET} $1"; }
err()  { echo -e "${RED}[-]${RESET} $1"; }
info() { echo -e "${BLUE}[*]${RESET} $1"; }

# Run as root directly, otherwise prefix privileged commands with sudo.
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    command -v sudo >/dev/null 2>&1 && SUDO="sudo" || { err "Need root or sudo."; exit 1; }
fi

have() { command -v "$1" >/dev/null 2>&1; }

# Where `go install` drops binaries, and where we publish them for everyone.
GOBIN_DIR="$(go env GOPATH 2>/dev/null)/bin"; GOBIN_DIR="${GOBIN_DIR:-$HOME/go/bin}"
DEST="/usr/local/bin"

# ---------------------------------------------------------------------------
# 1. System packages (apt)
# ---------------------------------------------------------------------------
#if have apt-get; then
#    log "Installing system packages via apt..."
#    export DEBIAN_FRONTEND=noninteractive
#    $SUDO apt-get update -qq
#    $SUDO apt-get install -y -qq \
#        golang-go git curl unzip build-essential \
#        python3 python3-pip pipx \
#        nmap jq seclists feroxbuster ffuf 2>/dev/null || \
#        warn "Some apt packages failed — go/pipx fallbacks below will cover most."
#else
#    warn "apt not found — install nmap, jq, seclists, golang, python3, pipx manually."
#fi

# ---------------------------------------------------------------------------
# 2. Go tools
# ---------------------------------------------------------------------------
if have go; then
    log "Installing Go tools (this can take a few minutes)..."
    # name|module path
    GO_TOOLS=(
        "httpx|github.com/projectdiscovery/httpx/cmd/httpx@latest"
        "katana|github.com/projectdiscovery/katana/cmd/katana@latest"
        "nuclei|github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest"
        "subfinder|github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
        "ffuf|github.com/ffuf/ffuf/v2@latest"
        "gowitness|github.com/sensepost/gowitness@latest"
        "assetfinder|github.com/tomnomnom/assetfinder@latest"
        "subzy|github.com/PentestPad/subzy@latest"
    )
    for entry in "${GO_TOOLS[@]}"; do
        name="${entry%%|*}"; mod="${entry#*|}"
        if have "$name"; then
            info "$name already installed — skipping"
            continue
        fi
        info "go install $name ..."
        if GOBIN="$GOBIN_DIR" go install "$mod" 2>/dev/null; then
            [ -x "$GOBIN_DIR/$name" ] && $SUDO cp "$GOBIN_DIR/$name" "$DEST/"
            log "$name installed"
        else
            err "Failed to build $name ($mod)"
        fi
    done
else
    err "go not found — cannot install httpx/katana/nuclei/subfinder/ffuf/gowitness/assetfinder/subzy."
fi

# ---------------------------------------------------------------------------
# 3. feroxbuster (fallback if apt didn't provide it)
# ---------------------------------------------------------------------------
if ! have feroxbuster; then
    warn "feroxbuster missing — trying official install script..."
    if curl -fsSL https://raw.githubusercontent.com/epi052/feroxbuster/main/install-nix.sh | bash 2>/dev/null; then
        [ -x ./feroxbuster ] && $SUDO mv ./feroxbuster "$DEST/"
    fi
    have feroxbuster || err "feroxbuster install failed — install manually (cargo/apt)."
fi

# ---------------------------------------------------------------------------
# 4. arjun (pipx preferred, pip fallback)
# ---------------------------------------------------------------------------
if ! have arjun; then
    log "Installing arjun..."
    if have pipx; then
        pipx install arjun >/dev/null 2>&1 && pipx ensurepath >/dev/null 2>&1
    fi
    have arjun || $SUDO pip3 install --break-system-packages arjun >/dev/null 2>&1
    have arjun || err "arjun install failed — try: pipx install arjun"
fi

# ---------------------------------------------------------------------------
# 5. nuclei templates (first-run download)
# ---------------------------------------------------------------------------
if have nuclei; then
    info "Updating nuclei templates..."
    nuclei -update-templates -silent >/dev/null 2>&1 || warn "nuclei template update skipped"
fi

# ---------------------------------------------------------------------------
# 6. Verify — matches the tools boringrecon looks for
# ---------------------------------------------------------------------------
echo
log "Verification:"
MISSING=0
for t in httpx katana feroxbuster arjun nuclei ffuf nmap gowitness \
         subfinder assetfinder subzy jq python3; do
    if have "$t"; then
        printf "  ${GREEN}✓${RESET} %-13s %s\n" "$t" "$(command -v "$t")"
    else
        printf "  ${RED}✗${RESET} %-13s MISSING\n" "$t"
        MISSING=$((MISSING + 1))
    fi
done

WL="/usr/share/seclists/Discovery"
if [ -d "$WL" ]; then
    printf "  ${GREEN}✓${RESET} %-13s %s\n" "seclists" "$WL"
else
    printf "  ${YELLOW}!${RESET} %-13s not at %s (vhost/ferox wordlists needed)\n" "seclists" "$WL"
fi

echo
if [ "$MISSING" -eq 0 ]; then
    log "All tools present. Run:  ./boringrecon example.com"
else
    warn "$MISSING tool(s) missing — boringrecon will skip those phases but still run."
fi
            
