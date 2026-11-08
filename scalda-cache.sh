#!/bin/sh
# Richiede tutte le URL della sitemap per riempire la cache nginx. Solo GET, nessuna modifica.
# Stesse richieste di prima; in piu' stampa una riga per URL: codice HTTP, tempo, URL.
# Se la connessione cade: "ERRORE curl=N URL". Il giro continua; a fine giro esce con errore se ce n'e' stato almeno uno.
ERR=$(mktemp)
get() { curl -sS "$@" || { r=$?; for u; do :; done; echo "ERRORE curl=$r $u" >&2; echo x >> "$ERR"; }; }
get -w '%{stderr}%{http_code} %{time_total}s %{url_effective}\n' https://campovisivoroma.it/sitemap.xml | grep -o '<loc>[^<]*' | sed 's/<loc>//' | grep '\.xml$' |
while read -r s; do get -w '%{stderr}%{http_code} %{time_total}s %{url_effective}\n' "$s" | grep -o '<loc>[^<]*' | sed 's/<loc>//'; done |
while read -r u; do get -o /dev/null -w '%{http_code} %{time_total}s %{url_effective}\n' "$u"; done
N=$(wc -l < "$ERR" | tr -d ' ')
echo "Errori: $N"
[ "$N" -eq 0 ]
