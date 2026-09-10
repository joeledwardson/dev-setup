---
title: "ADR-012 Observability re-visited"
---

# ADR-012 - Observability re-visited

## Brief
Well last ADR (ADR-005) I let claude/codex write everything so I'm going to write this one by hand. My experiences trialing out different observability platforms.

My requirements thus far are some way to monitor/alert on:
- CPU
- RAM
- Networking
- GPU
- INodes
- Storage
- Systemd failures/logging
- Health checks
- Login failure (password/key)

I guess this covers observability in general so i asksed claude to spin up different systems to have a play. My initial reactions are:

| Name | Enterprise-slop-ometer | TLDR |
|---|---|---|
| Zabbix | 🟥 | looks like LAMP stack built in 90s |
| Netdata | 🟨 | was great, now they propmt cloud login on landing page |


Now about systemd, munin seems a good candidate for this but it looks like it was built early 2000s jeesus.

For the open source observability, both the below are capable but very old and non polished


| Name | Enterprise-slop-ometer | Visual Appeal | TLDR |
|---|---|---|---|
| Monit | 🟩 | 🟥 | VERY OLD - graphs look like 1990s matlab |
| monitorix | 🟩 | 🟥 | again VERY OLD - seems like an oldver version of netdata |
| hyperdx | 🟩 | 🟩 | looks nice honestly |
| openoberve | 🟩 | 🟨 | charts are not the cleanest |
| signoz | 🟩 | 🟩🟩 | super clean, great dashboard UI |


beszel im going to rule out as it is not every extensive - i consider it more of a great "plug and play" until you exceed its capabilities

for monitoring endpoints

| Name | What's it for | Simplicity | TLDR |
|---|---|---|---|
| Gatus | endpoint health | 🟩 nix declarative config | seems great simple overview |
| Uptime Kuma | endpiont health | 🟨 no nix declarative config | nice UI, not as fresh as Gatus |
| Ntfy | sending notifications | good | i already use it, works well |

## systemd and processes

This was the missing bit. I do not need Munin for it.

worker207 now runs the Prometheus community `systemd_exporter`. The existing
OpenTelemetry Collector scrapes its OpenMetrics endpoint and sends the results to
SigNoz over OTLP. The Collector also has its standard per-process scraper enabled.
There is no Prometheus server and no SigNoz agent on the machine.

The `Systemd and Processes` dashboard in SigNoz shows currently failed services,
automatic restart activity, CPU by executable and physical memory by executable.
The underlying metrics are standard `systemd_*` Prometheus metrics and `process.*`
OpenTelemetry metrics, so changing the UI later does not mean changing the agents.

The dashboard itself is necessarily SigNoz-shaped. It is generated from SigNoz's
current V2 host-dashboard schema and reconciled through the supported dashboard API.
That is presentation lock-in, not collection lock-in, and the source of truth remains
in Nix.

One caveat: restart counters only cover services configured to restart automatically.
A service that fails once and stays dead is covered by its failed-state metric and by
the existing systemd `OnFailure=` notification. The journal in SigNoz remains the
place to answer why it failed.

## InfluxDB / Chronograf trial

This is running as a separate experiment rather than replacing SigNoz. Telegraf
collects its normal host metrics, every userspace process through `procstat`, and
systemd unit state through D-Bus. It writes to InfluxDB 3 Core; Chronograf 1.11 is
connected to the resulting `telegraf` database on port 8088.

InfluxDB itself only listens on localhost. The point of this trial is to see whether
Chronograf's built-in Telegraf host and process views are genuinely more useful than
building the equivalent presentation in SigNoz. It also gives the older TICK workflow
a fair test against the newer OTLP stack.
