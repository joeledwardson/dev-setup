(
    set -a
    source <(sudo cat /run/agenix/gatus-env)
    set +a
    http POST https://gatus.joels-netflix.com/api/v1/endpoints/backups_sparkyfitness/external \
        "Authorization:Bearer $GATUS_BACKUP_TOKEN" success==false error=="manual test"
)
