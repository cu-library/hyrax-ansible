#! /usr/bin/env bash

# Delete older backups
(echo -n "$(date --rfc-3339=seconds) - deleting older daily backups - " && find "{{ hyrax_backups_directory }}/daily" -mindepth 1 -maxdepth 1 -mtime +7 -name '*.tar.gz' -type f -delete -print | grep --color=never 'tar.gz' || echo "none found") >> /var/log/hyrax/backup.log 2>&1

# Fcrepo
(echo -n "$(date --rfc-3339=seconds) - creating fcrepo backup - " && curl --silent -X POST -d "{{ hyrax_backups_directory }}/current/fcrepo" "localhost:8080/fcrepo/rest/fcr:backup") >> /var/log/hyrax/backup.log 2>&1
(echo -n " size: " &&  du -hs "{{ hyrax_backups_directory }}/current/fcrepo" | cut -f 1) >> /var/log/hyrax/backup.log 2>&1

# PostgreSQL
(echo -n "$(date --rfc-3339=seconds) - creating postgres backup - " && su - postgres -c "pg_dumpall --file={{ hyrax_backups_directory }}/current/postgres/backup.sql") >> /var/log/hyrax/backup.log 2>&1
(echo -n " size: " &&  du -hs "{{ hyrax_backups_directory }}/current/postgres" | cut -f 1) >> /var/log/hyrax/backup.log 2>&1

# Redis
(echo -n "$(date --rfc-3339=seconds) - creating redis backup - " && cp /var/lib/redis/dump.rdb "{{ hyrax_backups_directory }}/current/redis/dump.rdb") >> /var/log/hyrax/backup.log 2>&1
(echo -n " size: " &&  du -hs "{{ hyrax_backups_directory }}/current/redis" | cut -f 1) >> /var/log/hyrax/backup.log 2>&1

# Hyrax
(echo -n "$(date --rfc-3339=seconds) - creating hyrax backup - " && tar --exclude=log --exclude=tmp/cache --exclude=tmp/pids --exclude=tmp/sessions --exclude=tmp/sockets -cf "{{ hyrax_backups_directory }}/current/hyrax/hyrax-root.tar" -C /var/www/hyrax/ hyrax-root) >> /var/log/hyrax/backup.log 2>&1
(echo -n " size: " &&  du -hs "{{ hyrax_backups_directory }}/current/hyrax" | cut -f 1) >> /var/log/hyrax/backup.log 2>&1

# All together, now!
(echo -n "$(date --rfc-3339=seconds) - archiving backups together - " && tar -czf "{{ hyrax_backups_directory }}/daily/hyrax-backup.tar.gz" -C "{{ hyrax_backups_directory }}/current" hyrax redis postgres fcrepo) >> /var/log/hyrax/backup.log 2>&1
(echo -n " size: " &&  du -hs "{{ hyrax_backups_directory }}/daily/hyrax-backup.tar.gz" | cut -f 1) >> /var/log/hyrax/backup.log 2>&1
checksum=$(md5sum {{ hyrax_backups_directory }}/daily/hyrax-backup.tar.gz | cut -d ' ' -f 1)
datestamp=$(date --rfc-3339=date)
(echo -n "$(date --rfc-3339=seconds) - adding timestamp - " && mv "{{ hyrax_backups_directory }}/daily/hyrax-backup.tar.gz" "{{ hyrax_backups_directory }}/daily/$datestamp-hyrax-backup-md5-$checksum.tar.gz" && echo "$datestamp-hyrax-backup-md5-$checksum.tar.gz") >> /var/log/hyrax/backup.log 2>&1

# Delete current backups
(echo -n "$(date --rfc-3339=seconds) - deleting temporary fcrepo data - " && rm -rf {{ hyrax_backups_directory }}/current/fcrepo/* && echo " done") >> /var/log/hyrax/backup.log 2>&1
(echo -n "$(date --rfc-3339=seconds) - deleting temporary postgres data - " && rm -f {{ hyrax_backups_directory }}/current/postgres/backup.sql && echo " done") >> /var/log/hyrax/backup.log 2>&1
(echo -n "$(date --rfc-3339=seconds) - deleting temporary redis data - " && rm -f {{ hyrax_backups_directory }}/current/redis/dump.rdb && echo " done") >> /var/log/hyrax/backup.log 2>&1
(echo -n "$(date --rfc-3339=seconds) - deleting temporary hyrax data - " && rm -f {{ hyrax_backups_directory }}/current/hyrax/hyrax-root.tar && echo " done") >> /var/log/hyrax/backup.log 2>&1
