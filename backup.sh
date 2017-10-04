!/bin/bash
set -e
#This script runs inside a docker container

HOST=$(hostname -I | tr -d '[[:space:]]')
PORT=8086
RETENTION=${RETENTION:-14}
DATE=`date +%m-%d-%Y`
BACKUPDIR=/tmp/Influx

create_backup_directories () {
# Check Backup Directory exists.
if [ ! -e "$BACKUPDIR" ]
      then
      mkdir -p "$BACKUPDIR"
fi
# Check Daily Directory exists.
if [ ! -e "${BACKUPDIR}/${DATE}" ]
      then
      mkdir -p "${BACKUPDIR}/${DATE}"
fi

}

#Deleting old backups older than 14 days
if [ $(find "$BACKUPDIR" -maxdepth 1 -type d | wc -l) -ge $RETENTION ]
  then find "$BACKUPDIR" -mindepth 1 -maxdepth 1 -type d -mtime +${RETENTION} -delete -print
fi

create_backup_directories
echo 'Backup Influx metadata'
influxd backup ${BACKUPDIR}/${DATE}

for db in $(python -c "import sys, json, requests; r = requests.get('http://${HOST}:${PORT}/query', params={'u':'admin', 'p':'admin', 'q':'show databases'}); print '\n'.join([db[0] for db in r.json()['results'][0]['series'][0]['values'][:]])"); do 
  echo "Creating backup for $db"
  influxd backup -database $db ${BACKUPDIR}/${DATE}/$db-backup
done
