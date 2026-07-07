# boringrecon

Automated web reconnaissance tool that runs a full pipeline and generates an interactive tree-map report.

## What it does

1. **Fingerprints** targets with httpx (status, title, tech stack)
2. **Crawls** with katana (authenticated if cookies provided)
3. **Scans** with nuclei (low-critical severity)
4. **Screenshots** with gowitness (full-page, every discovered endpoint)
5. **Discovers vhosts** with ffuf and automatically re-scans them
6. **Port scans** with nmap
7. **Generates** a single `report.html` — interactive tree-map with per-host tech stacks, vulnerabilities, parameters, and full-quality screenshots

## Install

```bash
# Already at /opt/boringrecon — just symlink into PATH:
ln -s /opt/boringrecon/boringrecon ~/.local/bin/boringrecon
```

## Usage

```
boringrecon [options] <domain|URL>

Options:
  -q               Quick mode (top-100 nmap, skip subdomain enum)
  -H <value|file>  Add custom HTTP header (repeatable)
  -h               Show help
```

## Examples

```bash
# Full scan on a domain
boringrecon example.com

# Quick scan on an IP
boringrecon -q http://10.10.11.5

# Authenticated scan with cookies
boringrecon -H 'Cookie: session=abc123' http://target.local

# Multiple headers from a file
boringrecon -H headers.txt target.com
```

## Output

Results are saved to `./<target>/`:

```
target/
  report.html        Interactive tree-map report
  crawl/
    endpoints.txt    Unique in-scope URLs
    params.txt       URLs with parameters
    js_files.txt     Discovered JavaScript files
  scans/
    nmap_full.txt    Port scan results
    nuclei.txt       Vulnerability findings
    vhosts.json      ffuf vhost discovery
  screenshots/       Full-page screenshots (referenced by report)
  subdomains/
    alive.txt        Alive hosts
    httpx.txt        Fingerprint data
    vhosts.txt       Discovered virtual hosts
```

## Report features

- Tree-map visualization of all discovered endpoints grouped by host
- Per-host tech stack display (click a host node)
- Vulnerability highlights with severity badges
- Full-quality screenshots (loaded from files, not embedded)
- Search/filter with visual dimming of non-matching nodes
- Click to select, double-click to expand/collapse
- Lightbox for screenshot zoom

## Requirements

Core (required):
- `httpx`, `katana`, `nuclei`, `gowitness` — [ProjectDiscovery](https://github.com/projectdiscovery) tools
- `nmap`, `ffuf`, `python3`, `jq`

Optional:
- `subfinder`, `amass` — subdomain enumeration (domain mode)
- `subzy` — subdomain takeover checks
- `seclists` — wordlists for ffuf vhost discovery
- `chromium` — used by gowitness for screenshots
                           
