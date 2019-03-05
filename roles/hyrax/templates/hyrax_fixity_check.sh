#! /usr/bin/env bash

cd /var/www/hyrax/current/
set -o allexport; source /var/www/hyrax/.env; set +o allexport
(echo -n "$(date --rfc-3339=seconds) " && /usr/local/bin/bundle exec rails runner "Hyrax::RepositoryFixityCheckService.fixity_check_everything" && echo "success" || echo "failure") >> /var/log/hyrax/fixitycheck.log 2>&1
