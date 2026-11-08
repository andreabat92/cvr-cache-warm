#!/bin/sh
# Tiene calda la cache delle 8 pagine chiave, solo GET, una richiesta alla volta.
# Ogni 4 minuti: le 8 pagine di CHIAVE senza cookie (home, /oct-roma/, /prenota/, /prezzi/ + 4 piu' visitate; prova 1 ora: a 4 min mai MISS).
# Una volta all'ora (e all'avvio): le stesse 4 pagine con iPhone UA + cookie cvrwarm=1.
# Una volta all'ora (e all'avvio): giro completo della sitemap, senza cookie.
# Ogni richiesta stampa: ora, x-cache-status, codice HTTP, tempo, URL (serve a ricavare la durata della cache nginx).
# Si ferma con errore dopo 2 richieste fallite di fila. Esce da solo dopo DURATA secondi (meno del timeout del job).
BASE=https://campovisivoroma.it
UA_TEL='Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1'
DURATA=${DURATA:-20400}   # 340 minuti
CICLO=240
GIRO_SITEMAP=3600
PAUSA=2
CHIAVE='/ /oct-roma/ /prenota/ /prezzi/ /esame-oct-valori-normali-come-leggere-i-risultati/ /metodo-gandolfo/ /patente/ /pressione-oculare-alta-sintomi-cause-e-quando-preoccuparsi/'
FALLITE=0
H=$(mktemp)

# get <url> [opzioni curl]: una richiesta, una riga di log, conta le fallite di fila.
get() {
  u=$1; shift
  if curl -sS --max-time 15 -D "$H" -o /dev/null -w '%{http_code} %{time_total}s' "$@" "$u" > "$H.out" 2> "$H.err"; then
    cod=$(cut -d' ' -f1 "$H.out")
    cs=$(tr -d '\r' < "$H" | grep -i '^x-cache-status:' | tail -1 | cut -d' ' -f2)
    echo "$(date -u +%H:%M:%S) ${cs:--} $(cat "$H.out") $u"
    case $cod in 2*|3*) FALLITE=0 ;; *) FALLITE=$((FALLITE+1)) ;; esac
  else
    echo "$(date -u +%H:%M:%S) ERRORE $(cat "$H.err") $u"
    FALLITE=$((FALLITE+1))
  fi
  if [ "$FALLITE" -ge 2 ]; then echo "Stop: 2 richieste fallite di fila"; exit 1; fi
  sleep "$PAUSA"
}

sitemap() {
  curl -sS --max-time 15 "$BASE/sitemap.xml" | grep -o '<loc>[^<]*' | sed 's/<loc>//' | grep '\.xml$' > "$H.idx" || { echo "ERRORE sitemap.xml"; exit 1; }
  sleep "$PAUSA"
  while read -r s; do
    curl -sS --max-time 15 "$s" | grep -o '<loc>[^<]*' | sed 's/<loc>//' >> "$H.urls"
    sleep "$PAUSA"
  done < "$H.idx"
  while read -r u; do get "$u"; done < "$H.urls"
  rm -f "$H.idx" "$H.urls"
}

INIZIO=$(date +%s); ULTIMO_GIRO=0; ULTIMO_COOKIE=0
while :; do
  T0=$(date +%s)
  if [ $((T0 - ULTIMO_GIRO)) -ge "$GIRO_SITEMAP" ]; then echo "== giro sitemap"; sitemap; ULTIMO_GIRO=$T0; fi
  echo "== pagine chiave"
  for p in $CHIAVE; do
    get "$BASE$p"
  done
  if [ $((T0 - ULTIMO_COOKIE)) -ge "$GIRO_SITEMAP" ]; then
    echo "== giro con cookie"
    for p in / /oct-roma/ /prenota/ /prezzi/; do get "$BASE$p" -A "$UA_TEL" -H 'Cookie: cvrwarm=1'; done
    ULTIMO_COOKIE=$T0
  fi
  T1=$(date +%s)
  [ $((T1 - INIZIO + CICLO)) -ge "$DURATA" ] && break
  A=$((CICLO - (T1 - T0))); [ "$A" -gt 0 ] && sleep "$A"
done
echo "Fine, nessun errore di fila"
