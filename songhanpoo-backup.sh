
#!/bin/bash

USER=""
PASSWORD=""
OUTPUT="/root/data/backup"

#rm "$OUTPUTDIR/*gz" > /dev/null 2>&1

databases=`mysql -u $USER -p$PASSWORD -e "SHOW DATABASES;" | tr -d "| " | grep -v Database`

for db in $databases; do
    if [[ "$db" != "information_schema" ]] && [[ "$db" != "performance_schema" ]] && [[ "$db" != "mysql" ]] && [[ "$db" != _* ]] ; then
        echo "Dumping database: $db"
        mysqldump -u $USER -p$PASSWORD --databases $db > `date +%Y%m%d`.$db.sql
       # gzip $OUTPUT/`date +%Y%m%d`.$db.sql
    fi
done

cd ~
cd /etc/nginx
tar -zcf `date +%Y%m%d`.backup-config-nginx.tar.gz /etc/nginx/conf.d
echo "Compress config nginx completed"

cd /usr/share
tar -zcf `date +%Y%m%d`.backup-source.tar.gz /usr/share/nginx
echo "Compress source web complete"

echo "Your backup location here: /root/data/"
mv /etc/nginx/*.tar.gz /data/backup/
mv /usr/share/*.tar.gz /data/backup/
mv /data/*.sql /data/backup/


sshpass -p $PASSWORD rsync -av /data/backup/*.* USER@HOST::DESTINATIONPATH
