#!/bin/bash
#se llama con parametro el nro de dia que aparece en el log
# ./full_log.sh 9    -- para el día 9

# Verifica si se ha pasado un argumento
if [ $# -eq 0 ]; then
    echo "Uso: $0 <número>"
    exit 1
fi

# Asignar el argumento a una variable
nro=$1

cp ../archivosbase/* .

../genlogs.sh $nro

python3 ../concatena2.py

python3 ../enrich.py

../filtragpsoauth.sh

python3 ../tetapa.py

python3 ../exttick.py

cp logetapa.csv logetapa_$nro.csv
cp logetapa1.csv logetapa1_$nro.csv
cp tickets.csv tickets_$nro.csv

cp *$nro.csv /Users/stjepan/Dropbox/clientesJMInext/Polpaico/04_INTERMEDIOS/cronos/logs
