-- Websurfx-Konfiguration
-- Privacy: Tor als Upstream nutzen

server_port = 8080
server_ip = "0.0.0.0"
logging = false
log_level = "warn"
proxy = "socks5://tor:9150"

upstream_search_engines = {
    DuckDuckGo = "https://duckduckgo.com/?q={query}",
    Startpage = "https://www.startpage.com/sp/search?query={query}",
    Searx = "https://searx.be/search?q={query}",
}

safe_search = 1
