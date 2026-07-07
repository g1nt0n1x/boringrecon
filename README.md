# boringrecon

Automated web reconnaissance tool that runs a full pipeline and generates an interactive tree-map report.

## What it does

1. **Fingerprints** targets with httpx (status, title, tech stack)
2. **Crawls** with katana (scope-locked to target FQDN)
3. **Brute-forces directories** with feroxbuster, then re-crawls new discoveries with katana
4. **Scans** with nuclei (low-critical severity)
5. **Screenshots** every discovered endpoint with gowitness
6. **Discovers vhosts** with ffuf and automatically re-scans them
7. **Port scans** with nmap
8. **Generates** a single `report.html` — interactive tree-map with per-host tech stacks, vulnerabilities, parameters, discovery source badges, and full-quality screenshots

## Install

```bash
# Already at /opt/boringrecon — just symlink into PATH:
ln -s /opt/boringrecon/boringrecon ~/.local/bin/boringrecon
```

## Usage

```
boringrecon [options] <domain|URL>

Options:
  -q               Quick mode (top-100 nmap, skip nuclei/vhosts)
  -d               Deep mode (enable subfinder + amass subdomain enum)
  -H <value|file>  Add custom HTTP header (repeatable)
  -h               Show help
```

## Examples

```bash
# Full scan on a domain
boringrecon example.com

# Quick scan on an IP
boringrecon -q http://10.10.11.5

# Deep scan with subdomain enumeration
boringrecon -d example.com

# Authenticated scan with cookies
boringrecon -H 'Cookie: session=abc123' http://target.local

# Multiple headers from a file
boringrecon -H headers.txt target.com
```

## Pipeline

```
httpx → katana → feroxbuster → katana (re-crawl) → nuclei → ffuf → nmap → gowitness
```

New directories from feroxbuster are re-crawled by katana. Discovered vhosts are automatically re-scanned through the full pipeline.

## Output

Results are saved to `./<target>/`:

```
target/
  report.html              Interactive tree-map report
  crawl/
    endpoints.txt          Unique in-scope URLs (merged)
    katana_urls.txt        URLs discovered by katana
    recrawl_urls.txt       URLs from re-crawling ferox discoveries
    vhost_urls.txt         URLs from vhost crawling
    params.txt             URLs with parameters
    param_names.txt        Unique parameter names
    js_files.txt           Discovered JavaScript files
  scans/
    nmap_full.txt          Port scan results
    nuclei.txt             Vulnerability findings
    feroxbuster.txt        Directory brute-force results
    vhosts.json            ffuf vhost discovery
  screenshots/             Full-page screenshots (referenced by report)
  subdomains/
    alive.txt              Alive hosts
    httpx.txt              Fingerprint data
    vhosts.txt             Discovered virtual hosts
```

## Report features

- Tree-map visualization of all discovered endpoints grouped by host
- Per-host tech stack display (click a host node)
- Vulnerability highlights with severity badges
- Discovery source badges — see whether each URL was found by katana, feroxbuster, re-crawl, or vhost scanning
- Yellow circles for nodes with URL parameters
- Full-quality screenshots (loaded from files, not embedded)
- Search/filter with visual dimming of non-matching nodes
- Click to select, double-click to expand/collapse
- Drag nodes to rearrange, pan and zoom the canvas
- Lightbox for screenshot zoom

## Requirements

Core (required):
- `httpx`, `katana`, `nuclei`, `gowitness` — [ProjectDiscovery](https://github.com/projectdiscovery) tools
- `feroxbuster` — directory brute-forcing
- `nmap`, `ffuf`, `python3`, `jq`

Optional:
- `subfinder`, `assetfinder` — subdomain enumeration (`-d` deep mode)
- `subzy` — subdomain takeover checks
- `seclists` — wordlists for ffuf and feroxbuster
- `chromium` — used by gowitness for screenshots
                              
