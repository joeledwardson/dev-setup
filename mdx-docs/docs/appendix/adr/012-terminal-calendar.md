---
title: "ADR-012 Terminal Calendars"
---

# ADR-012 Terminal calendars
The purpose of this ADR is to have a look at terminal solutions to calendar management as I'm getting tired of using the web UI to create calendar events

## Introduction
So for whatever reason i have to create a client ID/client secret in GCP console to be able to use google calendar. so
.1 enable the oauth API
.2 go to the google auth platform and create an "app" (have to filling developer contact information and all that shite)
.3 create an oauth 2.0 client ID which gives the client ID and client secret
.4 add my personal email as a test user

## Clients
So trying out a few different terminal calendars

| Name | Has TUI | ergonomics | issues | TLDR | 
|---|---|---|---|---|
| `gcalcli` | 🟥 | N/A | | good cli tool  |
| `calcurse` | 🟩 | 🟥  | google auth involved pasting an auth code, couldnt get it to work| old, written in c |
| `aion` | 🟩 | ? | managed to get it to work with `bun dev` but its prety janky | new, immature |



