#!/bin/sh
# Richiede tutte le URL della sitemap per riempire la cache nginx. Solo GET, nessuna modifica.
curl -s https://campovisivoroma.it/sitemap.xml | grep -o '<loc>[^<]*' | sed 's/<loc>//' | grep '\.xml$' |
while read -r s; do curl -s "$s" | grep -o '<loc>[^<]*' | sed 's/<loc>//'; done |
while read -r u; do curl -s -o /dev/null "$u"; done
