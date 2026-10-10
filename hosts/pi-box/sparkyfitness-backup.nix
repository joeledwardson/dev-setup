{ pkgs, config, ... }:

let
  backupGlob = "sparkyfitness_full_backup_*.tar.gz";
  # SparkyFitness backs up daily, so give it a day plus 2 hours of slack
  maxBackupAgeMinutes = 26 * 60;
  keepLocalCopiesDays = 30;
  # key is "<group>_<name>" of the external endpoint in hosts/streaming-server/gatus.nix
  gatusPushUrl = "https://gatus.joels-netflix.com/api/v1/endpoints/backups_sparkyfitness/external";
in {
  # only GATUS_BACKUP_TOKEN is used here, the rest is for gatus itself
  age.secrets.gatus-env.file = ../../secrets/gatus-env.age;

  # copies SparkyFitness's own backups and fails if the newest is too old, since SparkyFitness only logs failures
  systemd.services.sparkyfitness-backup-pull = {
    description = "Copy SparkyFitness backups from streaming-server";
    after = [ "network-online.target" "tailscaled.service" ];
    wants = [ "network-online.target" ];
    path = [ pkgs.openssh pkgs.rsync pkgs.findutils pkgs.httpie ];

    script = ''
      # httpie url-encodes the `==` query params for us
      reportFailure() {
        http --check-status --ignore-stdin POST "${gatusPushUrl}" \
          "Authorization:Bearer $GATUS_BACKUP_TOKEN" \
          success==false error=="$1"
      }

      # -a keeps modified times for the age check below; fails too if no backups match
      if ! rsync -a 'streaming-server:/var/lib/sparkyfitness/backup/${backupGlob}' "$STATE_DIRECTORY/"; then
        reportFailure "rsync from streaming-server failed, see journalctl -u sparkyfitness-backup-pull on pi-box"
        exit 1
      fi

      recentBackups=$(find "$STATE_DIRECTORY" -name '${backupGlob}' -mmin -${toString maxBackupAgeMinutes})
      if [ -z "$recentBackups" ]; then
        reportFailure "no SparkyFitness backup from the last ${toString maxBackupAgeMinutes} minutes on streaming-server"
        exit 1
      fi

      find "$STATE_DIRECTORY" -name '${backupGlob}' -mtime +${toString keepLocalCopiesDays} -delete

      http --check-status --ignore-stdin POST "${gatusPushUrl}" \
        "Authorization:Bearer $GATUS_BACKUP_TOKEN" \
        success==true
    '';

    serviceConfig = {
      Type = "oneshot";
      # Tailscale SSH lets claude in on streaming-server, and the backup files there are world-readable
      User = "claude";
      StateDirectory = "sparkyfitness-backups";
      EnvironmentFile = config.age.secrets.gatus-env.path;
    };
  };

  systemd.timers.sparkyfitness-backup-pull = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      # an hour after SparkyFitness's own 02:00 UTC backup
      OnCalendar = "*-*-* 03:00:00 UTC";
      Persistent = true;
    };
  };
}
