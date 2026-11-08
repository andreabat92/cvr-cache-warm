#!/bin/sh
# PROVA: 30 richieste GET a /prezzi/ (senza cookie), una al minuto. Misura dopo quanto cambia x-cache-status.
# Una richiesta alla volta, --max-time 15, stop dopo 2 errori di fila. Riga: ora, x-cache-status, codice, tempo.
U=https://campovisivoroma.it/prezzi/
H=$(mktemp); F=0; i=0
while [ "$i" -lt 30 ]; do
  i=$((i+1))
  if curl -sS --max-time 15 -D "$H" -o /dev/null -w '%{http_code} %{time_total}s' "$U" > "$H.o" 2> "$H.e"; then
    cs=$(tr -d '\r' < "$H" | grep -i '^x-cache-status:' | tail -1 | cut -d' ' -f2)
    echo "$(date -u +%H:%M:%S) ${cs:--} $(cat "$H.o") $U"
    case $(cut -d' ' -f1 "$H.o") in 2*|3*) F=0 ;; *) F=$((F+1)) ;; esac
  else
    echo "$(date -u +%H:%M:%S) ERRORE $(cat "$H.e") $U"; F=$((F+1))
  fi
  [ "$F" -ge 2 ] && { echo "Stop: 2 fallite di fila"; exit 1; }
  sleep 60
done
echo "Fine prova"
