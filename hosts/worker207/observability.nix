# =======================================================================
# worker207 — observability trial
# =======================================================================
# Every self-hosted monitoring stack worth trying, running side by side on the
# same box so they can be compared on identical hardware, plus the alerting
# paths that none of them cover well on their own (systemd unit failure,
# failed logins, inodes).
#
# This file is deliberately self-contained: delete the import in
# configuration.nix and everything here goes away.
#
# Ports. nixos-base already opens 3000-3099 and 8000-9999, so anything placed
# in those ranges needs no extra firewall rule; 2812 and 19999 are opened at
# the bottom of this file.
#
#   8080   signoz            — hardcoded upstream, no config knob; hence zabbix moved
#   8081   munin static HTML (nginx vhost)
#   8082   ntfy              — local notification hub; every alert lands here
#   8083   gatus
#   8084   monitorix         (its own built-in Perl HTTP server)
#   8085   hyperdx / ClickStack
#   8086   openobserve
#   8087   zabbix web        (nginx vhost -> php-fpm)
#   8088   chronograf        — InfluxDB/Telegraf trial UI
#   3001   uptime-kuma
#   19999  netdata
#   2812   monit
#   10050  zabbix agent      (localhost only)
#   10051  zabbix server     (localhost only)
#   8123   clickhouse http   (localhost only, signoz's telemetry store)
#   8181   influxdb 3 core   (localhost only; Chronograf uses host networking)
#   9000   clickhouse native (localhost only)
{ config, pkgs, lib, ... }:

let
  ntfyPort = 8082;
  ntfyUrl = "http://127.0.0.1:${toString ntfyPort}";
  openObserveUrl = "http://127.0.0.1:8086";
  # Basic auth for claude@worker207.local:observability. This is no more secret
  # than the root password already used below to seed this disposable trial.
  # Replace both with an agenix-backed ingestion token before adding hosts.
  openObserveAuth =
    "Basic Y2xhdWRlQHdvcmtlcjIwNy5sb2NhbDpvYnNlcnZhYmlsaXR5";
  # Created by HyperDX when the trial account was provisioned. Like the
  # OpenObserve credential above, move this ingestion key to agenix before
  # accepting telemetry from any other machine.
  hyperdxIngestionKey = "94e7c832-3c36-48a2-8001-93295d79f710";

  # OpenObserve's official dashboard for the Collector host_metrics receiver.
  # Pinning the content hash keeps rebuilds reproducible while avoiding a
  # locally maintained copy of a dashboard upstream already owns.
  hostMetricsDashboard = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/openobserve/dashboards/main/hostmetrics/Host%20Metrics.dashboard.json";
    name = "openobserve-host-metrics-dashboard.json";
    hash = "sha256-Xzh82gbgmoBSka/LhBYI1fr84Hh1M6DACkEHsnK86Wk=";
  };

  # SigNoz's maintained VM host dashboard. This is the current V2/Perses
  # schema, not the retired V1 dashboard format.
  signozHostMetricsDashboard = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/SigNoz/dashboards/refs/heads/main/hostmetrics/hostmetrics.json";
    name = "signoz-host-metrics-dashboard.json";
    hash = "sha256-aNzPocOTzZsXihRdece3TysThgUlTwwo6TYH+x4cW4I=";
  };

  # SigNoz does not currently publish a systemd dashboard template. Build one
  # from its maintained V2 host template so the panel/query schema continues
  # to come from upstream; only the four metric selections below are ours.
  signozSystemdDashboard = pkgs.runCommand "signoz-systemd-processes-dashboard.json" {
    nativeBuildInputs = [ pkgs.jq ];
  } ''
    jq '
      def group($name; $context): {
        name: $name, signal: "", fieldContext: $context,
        fieldDataType: "string"
      };
      def query($metric; $time; $space; $filter; $groups; $legend): {
        kind: "scalar",
        spec: {
          name: "A",
          plugin: {
            kind: "signoz/BuilderQuery",
            spec: {
              name: "A", stepInterval: 30, signal: "metrics", source: "",
              aggregations: [{
                metricName: $metric, temporality: "",
                timeAggregation: $time, spaceAggregation: $space,
                reduceTo: "avg"
              }],
              disabled: false, filter: { expression: $filter },
              groupBy: $groups, order: [], limit: 25,
              having: { expression: "" }, functions: [], legend: $legend
            }
          }
        }
      };
      def table($base; $title; $description; $metric; $time; $space;
                $filter; $groups; $legend; $unit):
        $base
        | .spec.display = { name: $title, description: $description }
        | .spec.plugin.spec.formatting.columnUnits = { A: $unit }
        | .spec.queries = [query($metric; $time; $space; $filter; $groups; $legend)];
      def number($base; $title; $description; $metric; $filter):
        $base
        | .spec.display = { name: $title, description: $description }
        | .spec.plugin.spec.formatting.unit = "none"
        | .spec.queries = [query($metric; "latest"; "sum"; $filter; []; "")];

      . as $root
      | ($root.spec.panels["92dd7aae-95eb-48ae-9d3a-6e062d468dab"]) as $table
      | ($root.spec.panels["b33f0bad-e623-4c2b-b854-12270f211690"]) as $number
      | .tags = [{key: "tag", value: "systemd"}, {key: "tag", value: "processes"}]
      | .spec.display = {
          name: "Systemd and Processes",
          description: "Portable systemd/OpenMetrics state and OpenTelemetry per-process resource usage"
        }
      | .spec.duration = "30m"
      | .spec.refreshInterval = "30s"
      | .spec.panels = {
          "systemd-failed": number($number; "Failed services now";
            "Current systemd services in the failed state";
            "systemd_unit_state"; "host.name IN $host.name AND state = '"'"'failed'"'"' AND type = '"'"'service'"'"'"),
          "systemd-restarts": table($table; "Service restarts";
            "Automatic restart triggers during each interval";
            "systemd_service_restart_total"; "increase"; "sum";
            "host.name IN $host.name"; [group("name"; "attribute")]; "{{name}}"; "none"),
          "process-cpu": table($table; "Process CPU";
            "Current CPU utilisation grouped by executable";
            "process.cpu.utilization"; "latest"; "sum";
            "host.name IN $host.name"; [group("process.executable.name"; "resource")];
            "{{process.executable.name}}"; "percentunit"),
          "process-memory": table($table; "Process memory";
            "Physical memory grouped by executable";
            "process.memory.usage"; "latest"; "sum";
            "host.name IN $host.name"; [group("process.executable.name"; "resource")];
            "{{process.executable.name}}"; "bytes")
        }
      | .spec.layouts = [{
          kind: "Grid",
          spec: {
            display: {title: "Service health", collapse: {open: true}},
            items: [
              {x: 0, y: 0, width: 3, height: 3, content: {"$ref": "#/spec/panels/systemd-failed"}},
              {x: 3, y: 0, width: 9, height: 6, content: {"$ref": "#/spec/panels/systemd-restarts"}}
            ]
          }
        }, {
          kind: "Grid",
          spec: {
            display: {title: "Expensive processes", collapse: {open: true}},
            items: [
              {x: 0, y: 0, width: 6, height: 8, content: {"$ref": "#/spec/panels/process-cpu"}},
              {x: 6, y: 0, width: 6, height: 8, content: {"$ref": "#/spec/panels/process-memory"}}
            ]
          }
        }]
    ' ${signozHostMetricsDashboard} > "$out"
  '';

  # Single notification entry point. Everything in this file — monit, munin,
  # netdata, the systemd failure handler, the failed-login watcher — sends
  # through this one script, so swapping ntfy for Slack/email later is a
  # one-file change rather than six.
  #
  #   obs-notify <topic> <title> [body words...]
  #
  # With no body words the body is read from stdin (munin feeds it that way).
  # Output is discarded on purpose: this script is called from a journal
  # watcher, and anything it printed would land back in the journal and be
  # re-matched, which is an infinite loop.
  obsNotify = pkgs.writeShellScriptBin "obs-notify" ''
    set -u
    topic="$1"
    title="$2"
    shift 2
    body="$*"
    if [ -z "$body" ]; then
      body="$(cat)"
    fi
    ${pkgs.curl}/bin/curl \
      --silent --output /dev/null --max-time 10 \
      --header "Title: $title" \
      --data "$body" \
      "${ntfyUrl}/$topic" >/dev/null 2>&1 || true
  '';

  # Handler invoked by the global systemd OnFailure drop-in below. Pulls the
  # last few journal lines for the failed unit so the notification says what
  # actually broke rather than just naming it.
  notifyFailure = pkgs.writeShellScriptBin "obs-notify-failure" ''
    set -u
    unit="$1"
    detail="$(${pkgs.systemd}/bin/journalctl --unit "$unit" --lines 10 --no-pager --output cat 2>/dev/null || true)"
    ${obsNotify}/bin/obs-notify systemd "unit-failed: $unit" "$unit entered a failed state.

    $detail"
  '';

  # Monitorix and SigNoz are not in nixpkgs; both are fetched release artifacts.
  # They live up here rather than beside their units because more than one
  # option below needs to refer to them.
  monitorix = pkgs.callPackage ../../pkgs/monitorix.nix { };
  signoz = pkgs.callPackage ../../pkgs/signoz.nix { };
  signozCollector = pkgs.callPackage ../../pkgs/signoz-otel-collector.nix { };
  chronograf = pkgs.stdenvNoCC.mkDerivation {
    pname = "chronograf";
    version = "1.11.0";
    src = pkgs.fetchzip {
      url = "https://dl.influxdata.com/chronograf/releases/chronograf-1.11.0_linux_amd64.tar.gz";
      hash = "sha256-OYn4v57DEdAHanOyNEqRrOnR1Z/nvkiROriV3Ep4Z7Y=";
      stripRoot = true;
    };
    installPhase = ''
      runHook preInstall
      install -Dm755 usr/bin/chronograf "$out/bin/chronograf"
      install -Dm755 usr/bin/chronoctl "$out/bin/chronoctl"
      cp -r usr/share "$out/share"
      runHook postInstall
    '';
  };

  signozCollectorConf = pkgs.writeText "signoz-otel-collector.yaml" ''
    receivers:
      otlp:
        protocols:
          grpc:
            endpoint: 127.0.0.1:14317
          http:
            endpoint: 127.0.0.1:14318
    processors:
      batch:
        timeout: 5s
        send_batch_size: 1024
    exporters:
      clickhousetraces:
        datasource: tcp://127.0.0.1:9000/signoz_traces
        use_new_schema: true
      signozclickhousemetrics:
        dsn: tcp://127.0.0.1:9000/signoz_metrics
      clickhouselogsexporter:
        dsn: tcp://127.0.0.1:9000/signoz_logs
        use_new_schema: true
    service:
      telemetry:
        metrics:
          # The host agent already owns the default :8888 endpoint. We do not
          # scrape this internal collector in the trial, so turn its own
          # process telemetry off instead of publishing another port.
          level: none
      pipelines:
        traces:
          receivers: [otlp]
          processors: [batch]
          exporters: [clickhousetraces]
        metrics:
          receivers: [otlp]
          processors: [batch]
          exporters: [signozclickhousemetrics]
        logs:
          receivers: [otlp]
          processors: [batch]
          exporters: [clickhouselogsexporter]
  '';

  # base_dir is already /var/lib/monitorix/www/ upstream, so it needs no change.
  # The two log paths do: the daemon runs as an unprivileged user and cannot
  # write to /var/log.
  #
  # The httpd log is replaced FIRST on purpose. Upstream writes the daemon's own
  # log_file with a tab before the '=', which is awkward to match exactly;
  # replacing the -httpd path first leaves '/var/log/monitorix' as the only
  # remaining occurrence, so the second rule can match the bare path and ignore
  # the whitespace entirely.
  monitorixConf = pkgs.runCommand "monitorix.conf" { } ''
    substitute ${monitorix}/share/monitorix/monitorix.conf.example $out \
      --replace-fail 'user = nobody' 'user = monitorix' \
      --replace-fail 'group = nobody' 'group = monitorix' \
      --replace-fail '/var/log/monitorix-httpd' '/var/lib/monitorix/httpd.log' \
      --replace-fail '/var/log/monitorix' '/var/lib/monitorix/monitorix.log'

    # Turn OFF the bundled Perl HTTP server; nginx + fcgiwrap serves Monitorix
    # instead (see services.nginx below). Its own server can serve the static
    # tree but cannot execute monitorix.cgi: it does a relative chdir("cgi")
    # while the daemon has already chdir'd to /tmp, so every graph request
    # 404s. Rather than patch upstream, nginx runs the CGI properly.
    #
    # 'enabled = y' appears once per graph module, so the edit is scoped to the
    # httpd_builtin block by address range rather than matched globally.
    sed -i '/<httpd_builtin>/,/<\/httpd_builtin>/ s/enabled = y/enabled = n/' $out
  '';

  # Follows the journal for authentication failures. Deliberately silent — see
  # the loop warning on obs-notify above.
  failedLoginWatch = pkgs.writeShellScriptBin "obs-failed-login-watch" ''
    set -u
    ${pkgs.systemd}/bin/journalctl --follow --lines 0 --no-pager --output cat \
      | ${pkgs.gnugrep}/bin/grep --line-buffered --extended-regexp \
          'Failed password|Failed publickey|Invalid user|authentication failure|Too many authentication failures|Connection closed by authenticating user' \
      | while IFS= read -r line; do
          ${obsNotify}/bin/obs-notify security "failed-login" "$line"
        done
  '';
in
{
  # =======================================
  # ntfy — the notification hub
  # =======================================
  # Self-hosted so nothing leaves the box during the trial. Every tool below
  # points at it. Subscribe by opening http://worker207:8082/<topic> or in the
  # ntfy mobile app. Topics in use: monit, munin, netdata, systemd, security.
  services.ntfy-sh = {
    enable = true;
    settings = {
      listen-http = ":${toString ntfyPort}";
      base-url = "http://worker207:${toString ntfyPort}";
    };
  };

  # =======================================
  # Monit — threshold checks, including inodes
  # =======================================
  # The only tool here that checks inode usage out of the box. Alerts go via
  # exec rather than monit's mail path, so there is no mailserver to configure.
  # Monit's exec splits the string on whitespace and runs it without a shell,
  # so obs-notify's topic and title must be single tokens.
  services.monit = {
    enable = true;
    config = ''
      set daemon 30 with start delay 30
      set log syslog
      set idfile /var/lib/monit/id
      set statefile /var/lib/monit/state

      set httpd port 2812
        allow 0.0.0.0/0
        allow admin:monit

      check system $HOST
        if loadavg (5min) > 12 for 3 cycles then exec "${obsNotify}/bin/obs-notify monit load-high 5-minute load average above 12"
        if cpu usage > 90% for 10 cycles then exec "${obsNotify}/bin/obs-notify monit cpu-high cpu above 90 percent for 5 minutes"
        if memory usage > 85% for 5 cycles then exec "${obsNotify}/bin/obs-notify monit memory-high memory above 85 percent"
        if swap usage > 40% for 5 cycles then exec "${obsNotify}/bin/obs-notify monit swap-high swap above 40 percent"

      check filesystem rootfs with path /
        if space usage > 80% then exec "${obsNotify}/bin/obs-notify monit disk-space-high root filesystem above 80 percent used"
        if inode usage > 80% then exec "${obsNotify}/bin/obs-notify monit inodes-high root filesystem above 80 percent of inodes used"

      check filesystem bootfs with path /boot
        if space usage > 80% then exec "${obsNotify}/bin/obs-notify monit boot-space-high boot partition above 80 percent used"

      check network wifi with interface wlp7s0
        if link down then exec "${obsNotify}/bin/obs-notify monit link-down wlp7s0 link is down"
    '';
  };

  # The monit module does not create a state directory, and monit will not
  # start without somewhere to put its idfile/statefile.
  systemd.tmpfiles.rules = [ "d /var/lib/monit 0700 root root - -" ];

  # =======================================
  # Munin — the old-school RRD poller
  # =======================================
  # munin-node exposes this host's plugins; munin-cron polls every 5 minutes
  # and regenerates static HTML + PNGs into /var/www/munin, which nginx serves
  # on 8081. No live dashboard — it is a wall of graphs, which is the point of
  # trying it.
  services.munin-node = {
    enable = true;
    extraConfig = ''
      cidr_allow 127.0.0.0/8
    '';
  };

  services.munin-cron = {
    enable = true;
    hosts = ''
      [worker207]
      address 127.0.0.1
      use_node_name yes
    '';
    # Munin hands the alert text to the command on stdin, which is why
    # obs-notify falls back to reading stdin when given no body arguments.
    extraGlobalConfig = ''
      contact.ntfy.command ${obsNotify}/bin/obs-notify munin munin-alert
      contact.ntfy.always_send warning critical
    '';
  };

  # =======================================
  # Zabbix — server + agent + web frontend
  # =======================================
  # The heavyweight of the four: a PostgreSQL-backed server, a local agent
  # reporting into it, and a PHP frontend behind nginx. createLocally provisions
  # the database and imports the schema on first start.
  services.zabbixServer = {
    enable = true;
    database = {
      type = "pgsql";
      createLocally = true;
    };
  };

  services.zabbixAgent = {
    enable = true;
    server = "127.0.0.1";
    settings = {
      # Must match the host name configured in the Zabbix frontend. Zabbix ships
      # with a built-in host called "Zabbix server" pointed at 127.0.0.1, so
      # using that name means the default template starts collecting with no
      # UI work at all.
      Hostname = "Zabbix server";
    };
  };

  services.zabbixWeb = {
    enable = true;
    frontend = "nginx";
    hostname = "zabbix.worker207";
    database = {
      type = "pgsql";
      # Peer authentication over the unix socket as the zabbix user, which is
      # also the user the php-fpm pool runs as. No password to manage.
      socket = "/run/postgresql";
    };
    nginx.virtualHost = {
      # Was 8080, moved to 8087: SigNoz hardcodes 8080 with no way to change it.
      listen = [{
        addr = "0.0.0.0";
        port = 8087;
      }];
      # Only vhost on 8087, so accept any Host header rather than requiring
      # the hostname above to resolve.
      default = true;
    };
  };

  # =======================================
  # Netdata — per-second, zero-config dashboard
  # =======================================
  # Included because "netdata style" is the reference point for what a metrics
  # dashboard should feel like. Watch its RSS during the trial: unbounded RAM
  # growth is a known upstream bug, which is why it was ruled out for pi-box.
  services.netdata = {
    enable = true;
    # nixpkgs builds netdata with withCloudUi = false, which ships the API but
    # NO dashboard — port 19999 answers /api/v1/* and 404s on /. The dashboard
    # is under Netdata's own NCUL1 licence rather than GPL, which is why it is
    # opt-in. allowUnfree is already set in nixos-base.
    package = pkgs.netdata.override { withCloudUi = true; };
    config = {
      global = {
        # Keep the local time-series database in RAM and capped, so the known
        # growth issue cannot run away on this box.
        "memory mode" = "ram";
      };
      web = {
        "bind to" = "0.0.0.0";
        "default port" = "19999";
      };
    };
    # Netdata has first-class ntfy support in its alarm notifier.
    configDir."health_alarm_notify.conf" = pkgs.writeText "health_alarm_notify.conf" ''
      SEND_NTFY="YES"
      DEFAULT_RECIPIENT_NTFY="${ntfyUrl}/netdata"
    '';
  };

  # =======================================
  # Uptime Kuma — liveness and status pages
  # =======================================
  # Answers "is the machine online" for anything it can reach. Note the honest
  # limitation: running ON worker207 it cannot report that worker207 is down —
  # that needs an external witness on pi-box or streaming-server. It is here so
  # the UI and its push-monitor type can be tried.
  services.uptime-kuma = {
    enable = true;
    settings = {
      HOST = "0.0.0.0";
      PORT = "3001";
    };
  };

  # =======================================
  # nginx — serves munin; zabbix adds its own vhost
  # =======================================
  # Runs monitorix.cgi on nginx's behalf, as the monitorix user so it can read
  # the RRDs and write the rendered PNGs into the state directory.
  services.fcgiwrap.instances.monitorix = {
    process.user = "monitorix";
    process.group = "monitorix";
    socket.user = config.services.nginx.user;
    socket.group = config.services.nginx.group;
  };

  services.nginx = {
    enable = true;

    # Monitorix on 8084, replacing its own HTTP server. base_url and base_cgi
    # in monitorix.conf are /monitorix and /monitorix-cgi, and the CGI writes
    # <img> tags against those paths, so the locations have to match them.
    virtualHosts."monitorix.worker207" = {
      listen = [{
        addr = "0.0.0.0";
        port = 8084;
      }];
      default = true;
      locations."= /" = { return = "302 /monitorix/"; };
      locations."/monitorix/" = {
        alias = "/var/lib/monitorix/www/";
        extraConfig = "autoindex on;";
      };
      locations."= /monitorix-cgi/monitorix.cgi" = {
        extraConfig = ''
          include ${pkgs.nginx}/conf/fastcgi_params;
          fastcgi_pass unix:${config.services.fcgiwrap.instances.monitorix.socket.address};
          fastcgi_param SCRIPT_FILENAME ${monitorix}/share/monitorix/monitorix.cgi;
          fastcgi_param DOCUMENT_ROOT /var/lib/monitorix/www;
        '';
      };
    };

    virtualHosts."munin.worker207" = {
      listen = [{
        addr = "0.0.0.0";
        port = 8081;
      }];
      default = true;
      root = "/var/www/munin";
      locations."/".extraConfig = ''
        autoindex on;
        index index.html;
      '';
    };
  };

  # =======================================
  # systemd — catch-all unit failure alerting
  # =======================================
  # A top-level drop-in: systemd applies /etc/systemd/system/service.d/*.conf to
  # EVERY service unit on the box, so nothing has to be enumerated and units
  # installed in future are covered automatically.
  #
  # The recursion guard matters. The handler is itself a .service, so it would
  # inherit its own OnFailure and loop. A unit-specific drop-in with the SAME
  # FILENAME masks the top-level one (name-specific directories outrank
  # type-wide ones), and an empty OnFailure= resets the list.
  systemd.packages = [
    (pkgs.writeTextDir "lib/systemd/system/service.d/50-notify-on-failure.conf" ''
      [Unit]
      OnFailure=obs-notify-failure@%n.service
    '')
    (pkgs.writeTextDir
      "lib/systemd/system/obs-notify-failure@.service.d/50-notify-on-failure.conf" ''
        [Unit]
        OnFailure=
      '')
  ];

  systemd.services."obs-notify-failure@" = {
    description = "Notify that %i entered a failed state";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${notifyFailure}/bin/obs-notify-failure %i";
    };
  };

  # =======================================
  # Failed login alerting
  # =======================================
  # Nothing in any of the four stacks watches authentication. This follows the
  # journal for SSH key/password failures and PAM failures and pushes them to
  # the security topic.
  systemd.services.obs-failed-login-watch = {
    description = "Notify on failed SSH or PAM authentication";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" "ntfy-sh.service" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${failedLoginWatch}/bin/obs-failed-login-watch";
      Restart = "always";
      RestartSec = 10;
    };
  };

  # =======================================
  # Gatus — health checks as config, not clicks
  # =======================================
  # The declarative counterpart to Uptime Kuma: endpoints, conditions and the
  # alert route all live in Nix, so there is no admin account and no web setup
  # step. Gatus speaks ntfy natively, and default-alert applies to every
  # endpoint so each one does not have to repeat it.
  services.gatus = {
    enable = true;
    settings = {
      web = {
        address = "0.0.0.0";
        port = 8083;
      };

      alerting.ntfy = {
        url = ntfyUrl;
        topic = "gatus";
        priority = 3;
        default-alert = {
          enabled = true;
          # Two consecutive failures before shouting, two successes before
          # declaring recovery — stops a single blip from paging.
          failure-threshold = 2;
          success-threshold = 2;
          send-on-resolved = true;
        };
      };

      # Status codes are asserted per endpoint rather than with one loose
      # catch-all, so an endpoint that starts redirecting is treated as a change
      # worth knowing about.
      endpoints = [
        {
          name = "beszel";
          url = "http://streaming-server:8090/";
          interval = "60s";
          conditions = [ "[STATUS] == 200" ];
        }
        {
          name = "monit";
          url = "http://127.0.0.1:2812/";
          interval = "60s";
          # 401 is the healthy answer here: the server is up and enforcing auth.
          conditions = [ "[STATUS] == 401" ];
        }
        {
          name = "munin";
          url = "http://127.0.0.1:8081/";
          interval = "60s";
          conditions = [ "[STATUS] == 200" ];
        }
        {
          name = "zabbix";
          url = "http://127.0.0.1:8087/";
          interval = "60s";
          conditions = [ "[STATUS] == 200" ];
        }
        {
          name = "netdata";
          url = "http://127.0.0.1:19999/api/v1/info";
          interval = "60s";
          conditions = [ "[STATUS] == 200" ];
        }
        {
          name = "ntfy";
          url = "http://127.0.0.1:8082/";
          interval = "60s";
          conditions = [ "[STATUS] == 200" ];
        }
        {
          name = "uptime-kuma";
          url = "http://127.0.0.1:3001/";
          interval = "60s";
          # / answers 302 to /setup or /dashboard, but Gatus follows redirects
          # by default, so the status it sees is the 200 at the end of the hop.
          conditions = [ "[STATUS] == 200" ];
        }
        {
          name = "openobserve";
          url = "http://127.0.0.1:8086/web/";
          interval = "60s";
          # Gatus spells a multi-value comparison as any(a, b) — a bare
          # "[STATUS] any 200 302" is a parse error and panics on startup.
          conditions = [ "[STATUS] == any(200, 302)" ];
        }
        {
          name = "signoz";
          url = "http://127.0.0.1:8080/api/v1/health";
          interval = "60s";
          conditions = [ "[STATUS] == 200" ];
        }
        {
          name = "hyperdx";
          url = "http://127.0.0.1:8085/api/health";
          interval = "60s";
          conditions = [ "[STATUS] == 200" ];
        }
        {
          name = "chronograf";
          url = "http://127.0.0.1:8088/";
          interval = "60s";
          conditions = [ "[STATUS] == 200" ];
        }
      ];
      # No disk/inode threshold endpoint here on purpose. Gatus asserts that a
      # thing RESPONDS; asserting on a metric value is monit's and netdata's
      # job, and both already cover disk space and inodes.
    };
  };

  # systemd_exporter is the standard Prometheus/OpenMetrics adapter for the
  # systemd D-Bus API. It owns no data and has no vendor-specific protocol;
  # the existing OTel Collector scrapes it locally and forwards the samples.
  services.prometheus.exporters.systemd = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 9558;
    extraFlags = [
      "--systemd.collector.enable-restart-count"
      "--systemd.collector.unit-include=.*\\.(service|socket|timer|mount)"
    ];
  };

  # =======================================
  # InfluxDB 3 + Telegraf + Chronograf trial
  # =======================================
  # Keep this parallel to the OTel trial. InfluxDB binds only to loopback;
  # Chronograf is the sole remotely reachable component. Authentication is
  # deliberately disabled for this local, disposable comparison so no trial
  # token has to be committed to the Nix store.
  systemd.services.influxdb3 = {
    description = "InfluxDB 3 Core trial";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.influxdb3}/bin/influxdb3 serve --node-id worker207 --object-store file --data-dir /var/lib/influxdb3 --http-bind 127.0.0.1:8181 --without-auth";
      DynamicUser = true;
      StateDirectory = "influxdb3";
      Restart = "on-failure";
      RestartSec = "5s";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
    };
  };

  systemd.services.influxdb3-provision = {
    description = "Create the InfluxDB Telegraf database";
    wantedBy = [ "multi-user.target" ];
    after = [ "influxdb3.service" ];
    requires = [ "influxdb3.service" ];
    before = [ "telegraf.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "provision-influxdb3" ''
        set -euo pipefail
        for attempt in $(${pkgs.coreutils}/bin/seq 1 30); do
          if ${pkgs.curl}/bin/curl --silent --fail http://127.0.0.1:8181/health >/dev/null; then
            break
          fi
          if [ "$attempt" -eq 30 ]; then
            echo 'InfluxDB API did not become ready' >&2
            exit 1
          fi
          ${pkgs.coreutils}/bin/sleep 1
        done
        ${pkgs.influxdb3}/bin/influxdb3 create database \
          --host http://127.0.0.1:8181 telegraf 2>&1 \
          | ${pkgs.gnugrep}/bin/grep --invert-match 'already exists' || true
      '';
    };
  };

  services.telegraf = {
    enable = true;
    extraConfig = {
      agent = {
        interval = "15s";
        flush_interval = "15s";
      };
      inputs = {
        cpu = {
          percpu = true;
          totalcpu = true;
          report_active = true;
        };
        disk = { };
        diskio = { };
        mem = { };
        net = { };
        processes = { };
        swap = { };
        system = { };
        systemd_units.pattern = "*.service";
        # Chronograf has a built-in procstat dashboard. For this trial collect
        # every userspace process; PID and process_name remain tags so the UI
        # can show a genuine process viewer rather than executable aggregates.
        procstat = {
          pattern = ".+";
          pid_finder = "native";
        };
      };
      # The v1-compatible output is intentional: InfluxDB 3 supports it, and
      # it is the schema expected by Chronograf's canned host/process views.
      outputs.influxdb = {
        urls = [ "http://127.0.0.1:8181" ];
        database = "telegraf";
        skip_database_creation = true;
      };
    };
  };
  systemd.services.telegraf = {
    after = [ "influxdb3-provision.service" ];
    requires = [ "influxdb3-provision.service" ];
  };

  systemd.services.chronograf = {
    description = "Chronograf InfluxDB trial UI";
    wantedBy = [ "multi-user.target" ];
    after = [ "influxdb3-provision.service" "telegraf.service" ];
    requires = [ "influxdb3-provision.service" ];
    environment = {
      PORT = "8088";
      BOLT_PATH = "/var/lib/chronograf/chronograf-v1.db";
      INFLUXDB_V3_SUPPORT_ENABLED = "true";
      INFLUXDB_TYPE = "influx-v3-core";
      INFLUXDB_URL = "http://127.0.0.1:8181";
      INFLUXDB_NAME = "worker207 InfluxDB 3";
      # Chronograf requires a non-empty token field even when the selected
      # InfluxDB Core server is explicitly running without authentication.
      INFLUXDB_TOKEN = "auth-disabled-for-local-trial";
      REPORTING_DISABLED = "true";
      CANNED_PATH = "${chronograf}/share/chronograf/canned";
      PROTOBOARDS_PATH = "${chronograf}/share/chronograf/protoboards";
      RESOURCES_PATH = "${chronograf}/share/chronograf/resources";
    };
    serviceConfig = {
      ExecStart = "${chronograf}/bin/chronograf";
      DynamicUser = true;
      StateDirectory = "chronograf";
      Restart = "on-failure";
      RestartSec = "5s";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
    };
  };

  # =======================================
  # OpenObserve — logs, metrics and traces in one binary
  # =======================================
  # In nixpkgs as a package but with no NixOS module, so the unit is written by
  # hand. This is the only thing in this file that can SEARCH logs, which is the
  # gap none of the other six fill.
  #
  # Credentials come from environment variables that OpenObserve reads only on
  # first start, when it seeds the root user into its SQLite metastore.
  systemd.services.openobserve = {
    description = "OpenObserve — logs, metrics and traces";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    environment = {
      ZO_ROOT_USER_EMAIL = "claude@worker207.local";
      ZO_ROOT_USER_PASSWORD = "observability";
      ZO_DATA_DIR = "/var/lib/openobserve";
      ZO_HTTP_ADDR = "0.0.0.0";
      ZO_HTTP_PORT = "8086";
      # Single node: SQLite metastore and local disk, no S3 or Postgres.
      ZO_LOCAL_MODE = "true";
      ZO_META_STORE = "sqlite";
      ZO_TELEMETRY = "false";
    };
    serviceConfig = {
      ExecStart = "${pkgs.openobserve}/bin/openobserve";
      DynamicUser = true;
      StateDirectory = "openobserve";
      WorkingDirectory = "/var/lib/openobserve";
      Restart = "on-failure";
      RestartSec = "10s";
      # Hardening kept mild: OpenObserve wants read/write over its whole data dir.
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      NoNewPrivileges = true;
    };
  };

  # =======================================
  # OpenTelemetry Collector — host agent for OpenObserve
  # =======================================
  # One agent sends both machine metrics and the system journal over OTLP.
  # OTLP is the boundary we own: replacing OpenObserve later only requires a
  # new exporter endpoint, not a new collector on every host.
  services.opentelemetry-collector = {
    enable = true;
    package = pkgs.opentelemetry-collector-contrib;
    settings = {
      extensions.file_storage = {
        directory = "/var/lib/opentelemetry-collector";
      };

      receivers = {
        host_metrics = {
          collection_interval = "30s";
          scrapers = {
            cpu = { };
            disk = { };
            filesystem = {
              # Keep real filesystems and ignore the large set of ephemeral
              # pseudo mounts created by systemd, containers and desktop apps.
              exclude_fs_types = {
                match_type = "strict";
                fs_types = [
                  "autofs"
                  "binfmt_misc"
                  "bpf"
                  "cgroup2"
                  "configfs"
                  "debugfs"
                  "devpts"
                  "devtmpfs"
                  "fusectl"
                  "hugetlbfs"
                  "mqueue"
                  "nsfs"
                  "overlay"
                  "proc"
                  "pstore"
                  "securityfs"
                  "squashfs"
                  "sysfs"
                  "tracefs"
                ];
              };
              metrics."system.filesystem.utilization".enabled = true;
            };
            load = { };
            memory = { };
            network = { };
            paging = { };
            processes = { };
            process = {
              # These two gauges make "what is expensive right now?" useful
              # without deriving it from cumulative CPU/memory counters.
              metrics = {
                "process.cpu.utilization".enabled = true;
                "process.memory.utilization".enabled = true;
                "process.uptime".enabled = true;
              };
              # Preserve the cgroup so a process can later be related back to
              # its systemd service without replacing this standards-based
              # collector with a bespoke script.
              resource_attributes."process.cgroup".enabled = true;
            };
          };
        };

        prometheus = {
          config.scrape_configs = [
            {
              job_name = "systemd";
              scrape_interval = "30s";
              static_configs = [ { targets = [ "127.0.0.1:9558" ]; } ];
            }
          ];
        };

        journald = {
          # Start with informational messages so SSH/PAM failures, systemd
          # state changes and application errors all reach OpenObserve.
          priority = "info";
          start_at = "end";
          storage = "file_storage";
        };
      };

      processors = {
        memory_limiter = {
          check_interval = "5s";
          limit_mib = 256;
          spike_limit_mib = 64;
        };
        resourcedetection = {
          detectors = [ "system" ];
          override = false;
          system.hostname_sources = [ "os" ];
        };
        batch = {
          timeout = "5s";
          send_batch_size = 1024;
        };
      };

      exporters."otlp_http/openobserve" = {
        endpoint = "${openObserveUrl}/api/default";
        compression = "gzip";
        headers = {
          Authorization = openObserveAuth;
          stream-name = "system_journal";
        };
      };
      exporters."otlp_http/signoz" = {
        endpoint = "http://127.0.0.1:14318";
      };
      exporters."otlp_http/hyperdx" = {
        endpoint = "http://127.0.0.1:4319";
        headers.Authorization = hyperdxIngestionKey;
      };

      service = {
        extensions = [ "file_storage" ];
        pipelines = {
          metrics = {
            receivers = [ "host_metrics" "prometheus" ];
            processors = [ "memory_limiter" "resourcedetection" "batch" ];
            exporters = [
              "otlp_http/openobserve"
              "otlp_http/signoz"
              "otlp_http/hyperdx"
            ];
          };
          logs = {
            receivers = [ "journald" ];
            processors = [ "memory_limiter" "resourcedetection" "batch" ];
            exporters = [
              "otlp_http/openobserve"
              "otlp_http/signoz"
              "otlp_http/hyperdx"
            ];
          };
        };
      };
    };
  };

  # Do not race OpenObserve during boot. The Collector retries failed exports,
  # but ordering these services avoids a noisy queue on ordinary restarts.
  systemd.services.opentelemetry-collector = {
    after = [ "network-online.target" "openobserve.service" "signoz-otel-collector.service" ];
    wants = [ "network-online.target" ];
    requires = [ "openobserve.service" ];
  };

  # Import the official dashboard through OpenObserve's API. Rebuilds update
  # the existing dashboard in place rather than making duplicates, so the UI
  # is derived from this pinned JSON even though OpenObserve stores it locally.
  systemd.services.openobserve-host-dashboard = {
    description = "Provision OpenObserve host metrics dashboard";
    wantedBy = [ "multi-user.target" ];
    after = [ "openobserve.service" "opentelemetry-collector.service" ];
    requires = [ "openobserve.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "provision-openobserve-host-dashboard" ''
        set -euo pipefail

        # OpenObserve can take a moment to open its HTTP listener after systemd
        # starts it. Wait for the authenticated API rather than guessing.
        for attempt in $(${pkgs.coreutils}/bin/seq 1 30); do
          if ${pkgs.curl}/bin/curl --silent --fail \
            --header 'Authorization: ${openObserveAuth}' \
            '${openObserveUrl}/api/default/dashboards' >/dev/null; then
            break
          fi
          if [ "$attempt" -eq 30 ]; then
            echo 'OpenObserve API did not become ready' >&2
            exit 1
          fi
          ${pkgs.coreutils}/bin/sleep 2
        done

        dashboards="$(${pkgs.curl}/bin/curl --silent --fail \
          --header 'Authorization: ${openObserveAuth}' \
          '${openObserveUrl}/api/default/dashboards')"
        dashboard_id="$(printf '%s' "$dashboards" \
          | ${pkgs.jq}/bin/jq --raw-output \
              '.dashboards[] | select(.title == "Host Metrics") | .dashboard_id' \
          | ${pkgs.coreutils}/bin/head --lines 1)"

        if [ -n "$dashboard_id" ]; then
          dashboard_hash="$(printf '%s' "$dashboards" \
            | ${pkgs.jq}/bin/jq --raw-output --arg id "$dashboard_id" \
                '.dashboards[] | select(.dashboard_id == $id) | .hash')"
          method=PUT
          endpoint="${openObserveUrl}/api/default/dashboards/$dashboard_id?folder=default&hash=$dashboard_hash"
        else
          method=POST
          endpoint="${openObserveUrl}/api/default/dashboards"
        fi

        ${pkgs.curl}/bin/curl --silent --show-error --fail \
          --request "$method" \
          --header 'Authorization: ${openObserveAuth}' \
          --header 'Content-Type: application/json' \
          --data-binary '@${hostMetricsDashboard}' \
          "$endpoint" >/dev/null
      '';
    };
  };

  # =======================================
  # Monitorix — Munin's older cousin
  # =======================================
  # Not in nixpkgs; fetched from its GitHub tag in ../../pkgs/monitorix.nix.
  # Included mainly as a comparison against Munin: same RRD-and-static-graphs
  # model, but it ships its own Perl HTTP server instead of needing nginx.
  #
  # Upstream's config is ~1100 lines of Config::General and is meant to be
  # edited in place, so rather than reproduce it, the packaged example is copied
  # and only the handful of paths and the port are rewritten.
  # Both the daemon and the CGI read this. The CGI has no --config flag: it
  # follows a pointer file baked into the package that names this exact path,
  # so the config must be here and not only in the store.
  environment.etc."monitorix/monitorix.conf".source = monitorixConf;

  systemd.services.monitorix = {
      description = "Monitorix system monitoring";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      path = [ pkgs.rrdtool ];
      # The built-in HTTP server serves static files from base_dir and executes
      # the CGI from a 'cgi' subdirectory relative to it, so both have to exist
      # on disk before the daemon starts.
      preStart = ''
        mkdir -p /var/lib/monitorix/www/{imgs,cgi}
        cp -f ${monitorix}/share/monitorix/*.png /var/lib/monitorix/www/ || true
        cp -rf ${monitorix}/share/monitorix/css /var/lib/monitorix/www/
        cp -rf ${monitorix}/share/monitorix/reports /var/lib/monitorix/www/
        ln -sf ${monitorix}/share/monitorix/monitorix.cgi /var/lib/monitorix/www/cgi/monitorix.cgi
        chmod -R u+w /var/lib/monitorix/www
      '';
      serviceConfig = {
        Type = "forking";
        # /etc/monitorix/monitorix.conf, not the store path directly: the CGI
        # finds its config through a baked-in pointer to this location, so the
        # daemon and the CGI have to agree on it. See pkgs/monitorix.nix.
        ExecStart = "${monitorix}/bin/monitorix -c /etc/monitorix/monitorix.conf -p /run/monitorix/monitorix.pid";
        PIDFile = "/run/monitorix/monitorix.pid";
        User = "monitorix";
        Group = "monitorix";
        StateDirectory = "monitorix";
        RuntimeDirectory = "monitorix";
        Restart = "on-failure";
        RestartSec = "10s";
      };
    };

  users.users.monitorix = {
    isSystemUser = true;
    group = "monitorix";
  };
  users.groups.monitorix = { };

  # =======================================
  # SigNoz — OpenTelemetry-native, needs ClickHouse
  # =======================================
  # Not in nixpkgs; the prebuilt release binary is fetched in
  # ../../pkgs/signoz.nix (its own metadata lives in SQLite, but telemetry
  # requires ClickHouse).
  #
  # SigNoz's own collector is required here: it contains both the ClickHouse
  # exporters and the schema migration commands. The ordinary contrib agent
  # above remains the host-facing collector and fans the same OTLP data out to
  # OpenObserve and SigNoz.
  services.clickhouse = {
    enable = true;
    # The migrator issues DDL `ON CLUSTER` even for a non-replicated install.
    # Define a one-node cluster and use ClickHouse's embedded Keeper for its
    # distributed DDL queue; there is still only one database replica.
    serverConfig = {
      remote_servers.cluster.shard = {
        internal_replication = false;
        replica = {
          host = "127.0.0.1";
          port = 9000;
        };
      };
      zookeeper.node = {
        host = "127.0.0.1";
        port = 9181;
      };
      keeper_server = {
        tcp_port = 9181;
        server_id = 1;
        log_storage_path = "/var/lib/clickhouse/coordination/log";
        snapshot_storage_path = "/var/lib/clickhouse/coordination/snapshots";
        coordination_settings = {
          operation_timeout_ms = 10000;
          session_timeout_ms = 30000;
          raft_logs_level = "warning";
        };
        raft_configuration.server = {
          id = 1;
          hostname = "127.0.0.1";
          port = 9234;
        };
      };
    };
  };

  systemd.services.signoz-telemetry-migrate = {
    description = "Create and update SigNoz ClickHouse telemetry schemas";
    after = [ "clickhouse.service" ];
    requires = [ "clickhouse.service" ];
    before = [ "signoz-otel-collector.service" "signoz.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "migrate-signoz-telemetry" ''
        set -euo pipefail
        args=(--clickhouse-dsn tcp://127.0.0.1:9000 --clickhouse-replication=false)
        # `migrate ready` is a Kubernetes/ZooKeeper readiness probe and still
        # queries system.zookeeper_connection with replication disabled. This
        # is deliberately a single-node ClickHouse, so run the idempotent
        # migrations themselves once its systemd unit is up.
        ${signozCollector}/bin/signoz-otel-collector migrate bootstrap "''${args[@]}"
        ${signozCollector}/bin/signoz-otel-collector migrate sync up "''${args[@]}"
        ${signozCollector}/bin/signoz-otel-collector migrate async up "''${args[@]}"
      '';
    };
  };

  systemd.services.signoz-otel-collector = {
    description = "SigNoz telemetry ingestion collector";
    wantedBy = [ "multi-user.target" ];
    after = [ "signoz-telemetry-migrate.service" ];
    requires = [ "signoz-telemetry-migrate.service" ];
    serviceConfig = {
      ExecStart = "${signozCollector}/bin/signoz-otel-collector --config ${signozCollectorConf}";
      Restart = "on-failure";
      RestartSec = "10s";
      DynamicUser = true;
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
    };
  };

  systemd.services.signoz =
    let
      signozConf = pkgs.writeText "signoz.yaml" ''
        web:
          enabled: true
          index: index.html
          directory: ${signoz}/share/signoz/web
        sqlstore:
          provider: sqlite
          sqlite:
            path: /var/lib/signoz/signoz.db
        telemetrystore:
          provider: clickhouse
          clickhouse:
            dsn: tcp://localhost:9000
      '';
    in
    {
      description = "SigNoz — OpenTelemetry-native observability";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "clickhouse.service" "signoz-telemetry-migrate.service" ];
      requires = [ "signoz-telemetry-migrate.service" ];
      serviceConfig = {
        # SigNoz logs a CRITICAL SECURITY ISSUE and leaves sessions tamperable
        # if SIGNOZ_TOKENIZER_JWT_SECRET is unset. It must not live in the
        # world-readable nix store, and it must survive restarts or everyone
        # gets logged out — so it is generated once into the state directory
        # and sourced from there.
        ExecStart = "${
            pkgs.writeShellScript "signoz-start" ''
              set -eu
              secret_file=/var/lib/signoz/jwt-secret
              if [ ! -s "$secret_file" ]; then
                ${pkgs.openssl}/bin/openssl rand -hex 32 > "$secret_file"
                chmod 600 "$secret_file"
              fi
              export SIGNOZ_TOKENIZER_JWT_SECRET="$(cat "$secret_file")"
              exec ${signoz}/bin/signoz server --config ${signozConf}
            ''
          }";
        DynamicUser = true;
        StateDirectory = "signoz";
        WorkingDirectory = "/var/lib/signoz";
        Restart = "on-failure";
        RestartSec = "15s";
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        NoNewPrivileges = true;
      };
    };

  systemd.services.signoz-host-dashboard = {
    description = "Provision SigNoz infrastructure dashboards";
    wantedBy = [ "multi-user.target" ];
    after = [ "signoz.service" "opentelemetry-collector.service" ];
    requires = [ "signoz.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      RuntimeDirectory = "signoz-dashboard";
      ExecStart = pkgs.writeShellScript "provision-signoz-host-dashboard" ''
        set -euo pipefail
        base=http://127.0.0.1:8080/api/v2

        for attempt in $(${pkgs.coreutils}/bin/seq 1 60); do
          if ${pkgs.curl}/bin/curl --silent --fail "$base/sessions/context?email=claude%40worker207.local" >/dev/null; then
            break
          fi
          if [ "$attempt" -eq 60 ]; then
            echo 'SigNoz API did not become ready' >&2
            exit 1
          fi
          ${pkgs.coreutils}/bin/sleep 2
        done

        org_id="$(${pkgs.curl}/bin/curl --silent --fail \
          "$base/sessions/context?email=claude%40worker207.local" \
          | ${pkgs.jq}/bin/jq --raw-output '.data.orgs[0].id')"
        token="$(${pkgs.curl}/bin/curl --silent --fail \
          --header 'Content-Type: application/json' \
          --data "{\"email\":\"claude@worker207.local\",\"password\":\"Observability1!\",\"orgId\":\"$org_id\"}" \
          "$base/sessions/email_password" \
          | ${pkgs.jq}/bin/jq --raw-output '.data.accessToken')"

        reconcile_dashboard() {
          title="$1"
          source="$2"
          output="$3"
          dashboards="$(${pkgs.curl}/bin/curl --silent --fail \
            --header "Authorization: Bearer $token" \
            "$base/dashboards?limit=100")"
          dashboard_row="$(printf '%s' "$dashboards" \
            | ${pkgs.jq}/bin/jq --compact-output --arg title "$title" \
                '.data.dashboards[] | select(.spec.display.name == $title)' \
            | ${pkgs.coreutils}/bin/head --lines 1)"
          dashboard_id="$(printf '%s' "$dashboard_row" | ${pkgs.jq}/bin/jq --raw-output '.id // empty')"

          if [ -n "$dashboard_id" ]; then
            dashboard_name="$(printf '%s' "$dashboard_row" | ${pkgs.jq}/bin/jq --raw-output '.name')"
            # generateName is valid when creating a dashboard, but the SigNoz
            # update API expects its resolved name instead.
            ${pkgs.jq}/bin/jq --arg name "$dashboard_name" \
              'del(.generateName) | .name = $name' "$source" > "$output"
            payload="$output"
            method=PUT
            endpoint="$base/dashboards/$dashboard_id"
          else
            payload="$source"
            method=POST
            endpoint="$base/dashboards"
          fi
          ${pkgs.curl}/bin/curl --silent --show-error --fail \
            --request "$method" --header "Authorization: Bearer $token" \
            --header 'Content-Type: application/json' \
            --data-binary "@$payload" "$endpoint" >/dev/null
        }

        reconcile_dashboard "Host Metrics" ${signozHostMetricsDashboard} \
          "$RUNTIME_DIRECTORY/host-metrics.json"
        reconcile_dashboard "Systemd and Processes" ${signozSystemdDashboard} \
          "$RUNTIME_DIRECTORY/systemd-processes.json"
      '';
    };
  };

  # HyperDX is distributed as ClickStack. The official all-in-one image is the
  # least misleading trial: it includes the exact ClickHouse schema, MongoDB,
  # HyperDX API/UI and opinionated Collector that upstream tests together.
  # Only the UI and one OTLP/HTTP endpoint are published on the host.
  virtualisation.oci-containers.backend = "docker";
  virtualisation.oci-containers.containers.hyperdx = {
    image = "clickhouse/clickstack-all-in-one:2.8.0";
    ports = [
      "8085:8080"
      "127.0.0.1:4319:4318"
    ];
    volumes = [ "hyperdx-data:/data/db" ];
    environment = {
      HYPERDX_APP_URL = "http://worker207";
      HYPERDX_LOG_LEVEL = "info";
      USAGE_STATS_ENABLED = "false";
    };
    extraOptions = [ "--pull=missing" ];
  };

  # HyperDX persists dashboards in MongoDB. Reconcile the small host dashboard
  # through its API so it is still described here rather than becoming a set
  # of unrepeatable clicks. The metric source itself is created automatically
  # by the all-in-one image when the first account is registered.
  systemd.services.hyperdx-host-dashboard = {
    description = "Provision HyperDX host metrics dashboard";
    wantedBy = [ "multi-user.target" ];
    after = [ "docker-hyperdx.service" "opentelemetry-collector.service" ];
    requires = [ "docker-hyperdx.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "provision-hyperdx-host-dashboard" ''
        set -euo pipefail
        base=http://worker207:8085/api
        cookie="$RUNTIME_DIRECTORY/cookie"

        for attempt in $(${pkgs.coreutils}/bin/seq 1 60); do
          if ${pkgs.curl}/bin/curl --noproxy '*' --silent --fail "$base/health" >/dev/null; then
            break
          fi
          if [ "$attempt" -eq 60 ]; then
            echo 'HyperDX API did not become ready' >&2
            exit 1
          fi
          ${pkgs.coreutils}/bin/sleep 2
        done

        ${pkgs.curl}/bin/curl --noproxy '*' --silent --fail \
          --cookie-jar "$cookie" --header 'Content-Type: application/json' \
          --data '{"email":"claude@worker207.local","password":"Observability1!"}' \
          "$base/login/password" >/dev/null

        source_id="$(${pkgs.curl}/bin/curl --noproxy '*' --silent --fail \
          --cookie "$cookie" "$base/sources" \
          | ${pkgs.jq}/bin/jq --raw-output '.[] | select(.kind == "metric") | ._id' \
          | ${pkgs.coreutils}/bin/head --lines 1)"
        test -n "$source_id"

        dashboard="$(${pkgs.jq}/bin/jq --null-input --arg source "$source_id" '
          def series($metric; $type; $aggregate; $delta): [{
            aggFn: $aggregate, aggCondition: "", aggConditionLanguage: "lucene",
            valueExpression: "Value", metricName: $metric, metricType: $type,
            isDelta: $delta
          }];
          def chart($id; $name; $metric; $type; $aggregate; $delta; $unit; $group; $x; $y): {
            id: $id, x: $x, y: $y, w: 6, h: 4,
            config: {
              name: $name, source: $source, displayType: "line",
              select: series($metric; $type; $aggregate; $delta),
              where: "", whereLanguage: "lucene", granularity: "auto",
              implicitColumnExpression: "", numberFormat: { output: $unit },
              filters: [], groupBy: [{ valueExpression: $group }]
            }
          };
          {
            name: "Host Metrics", tags: ["host", "nix-managed"],
            tiles: [
              chart("cpu"; "CPU time by state"; "system.cpu.time"; "sum"; "sum"; true; "number"; "Attributes[\u0027state\u0027]"; 0; 0),
              chart("memory"; "Memory by state"; "system.memory.usage"; "sum"; "avg"; false; "byte"; "Attributes[\u0027state\u0027]"; 6; 0),
              chart("filesystem"; "Filesystem usage"; "system.filesystem.usage"; "sum"; "avg"; false; "byte"; "Attributes[\u0027state\u0027]"; 0; 4),
              chart("network"; "Network I/O"; "system.network.io"; "sum"; "sum"; true; "byte"; "Attributes[\u0027direction\u0027]"; 6; 4)
            ]
          }
        ')"

        dashboard_id="$(${pkgs.curl}/bin/curl --noproxy '*' --silent --fail \
          --cookie "$cookie" "$base/dashboards" \
          | ${pkgs.jq}/bin/jq --raw-output '.[] | select(.name == "Host Metrics") | ._id' \
          | ${pkgs.coreutils}/bin/head --lines 1)"
        if [ -n "$dashboard_id" ]; then
          method=PATCH
          endpoint="$base/dashboards/$dashboard_id"
        else
          method=POST
          endpoint="$base/dashboards"
        fi
        ${pkgs.curl}/bin/curl --noproxy '*' --silent --show-error --fail \
          --request "$method" --cookie "$cookie" \
          --header 'Content-Type: application/json' --data "$dashboard" \
          "$endpoint" >/dev/null
      '';
      RuntimeDirectory = "hyperdx-dashboard";
    };
  };

  # obs-notify on the system PATH so alerts can be fired by hand while testing.
  environment.systemPackages = [ obsNotify pkgs.monit ];

  # 2812 (monit) and 19999 (netdata) fall outside the ranges nixos-base opens.
  networking.firewall.allowedTCPPorts = [ 2812 19999 ];
}
