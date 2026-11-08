#!/bin/sh
# PROVA 1 ora: ogni 4 minuti home, /oct-roma/, /prenota/, /prezzi/ senza cookie (15 cicli, 60 richieste).
# Una richiesta alla volta, pausa 2 s, --max-time 15, stop dopo 2 errori di fila.
# Riga: ora, x-cache-status, codice, tempo, URL.
B=https://campovisivoroma.it
H=$(mktemp); F=0; i=0
while [ "$i" -lt 15 ]; do
  i=$((i+1)); T0=$(date +%s)
  for p in / /oct-roma/ /prenota/ /prezzi/; do
    u=$B$p
    if curl -sS --max-time 15 -D "$H" -o /dev/null -w '%{http_code} %{time_total}s' "$u" > "$H.o" 2> "$H.e"; then
      cs=$(tr -d '\r' < "$H" | grep -i '^x-cache-status:' | tail -1 | cut -d' ' -f2)
      echo "$(date -u +%H:%M:%S) ${cs:--} $(cat "$H.o") $u"
      case $(cut -d' ' -f1 "$H.o") in 2*|3*) F=0 ;; *) F=$((F+1)) ;; esac
    else
      echo "$(date -u +%H:%M:%S) ERRORE $(cat "$H.e") $u"; F=$((F+1))
    fi
    [ "$F" -ge 2 ] && { echo "Stop: 2 fallite di fila"; exit 1; }
    sleep 2
  done
  A=$((240 - ($(date +%s) - T0))); [ "$A" -gt 0 ] && [ "$i" -lt 15 ] && sleep "$A"
done
echo "Fine prova"
