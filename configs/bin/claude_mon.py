#!/usr/bin/env -S uv run --quiet python
"""claude-mon — monitor Claude Code session states across hosts. No deps.

States (see docs/appendix/adr/003-claude-session-monitor.md):
  running  — Claude is busy
  pending  — Claude stopped/asking AND you are not focused on it  (needs you)
  idle     — Claude stopped/asking AND you are focused on it

Subcommands:
  collect   read THIS host's sessions + focus bits -> JSON  (run locally or over SSH)
  snapshot  aggregate local + remote (ssh) collects, compute states, print one line each

It's one-shot by design — poll it for a live view: a Waybar custom module with
"interval": 2, or `watch -n2 claude-mon snapshot`. (The event-driven watch/poke daemon
from ADR-003 is deliberately deferred — not worth the threads/ntfy maintenance for v1.)

Layout: PURE LOGIC (no I/O — the docstrings carry runnable `>>>` examples that double as the
test suite), then HOST I/O, AGGREGATION, CLI. Run it and see:
  ./claude_mon.py snapshot          # live: this host's sessions and their state
  ./claude_mon.py collect | jq      # raw per-host data the snapshot is built from
  ./claude_mon.py selftest          # run the doctests + print example rendered output
  python -m doctest claude_mon.py   # same doctests, silent unless something fails

Test seams (env): CLAUDE_MON_SESSIONS_DIR, CLAUDE_MON_ACTIVE_PID (override hyprland
active-window pid), CLAUDE_MON_SSH_HOSTS_FOCUSED (comma list of hosts whose SSH terminal
is the active local window), CLAUDE_MON_SSH / CLAUDE_MON_REMOTE_CMD (ssh + remote command).
"""
import argparse
import json
import os
import shlex
import subprocess
import time
from pathlib import Path

HOST = os.uname().nodename
STALE_BUSY_SECS = 120  # busy but updatedAt older than this -> reported "stale", not running


# ─────────────────────── PURE LOGIC (no I/O — unit-testable in isolation) ───────────────────────

def build_record(data, env, pane_focused, now_ms, host=HOST):
    """Shape one session record from already-read inputs. Pure: no I/O, so callable with plain dicts.

    In: data — parsed session JSON; env — that pid's environ dict; pane_focused — tmux focus
    bool/None (the caller computed it); now_ms — epoch ms for staleness; host — owning host.
    Out: the session dict the rest of the tool passes around.

    >>> r = build_record({"sessionId": "abcd1234", "cwd": "/home/me/api", "status": "idle"},
    ...                  {"TMUX": "1", "TMUX_PANE": "%3", "TERMINAL_WINDOW_PID": "555"},
    ...                  pane_focused=True, now_ms=0, host="jollof-home")
    >>> r["project"], r["tmux_pane"], r["terminal_window_pid"], r["pane_focused"]
    ('api', '%3', 555, True)
    >>> build_record({"status": "idle", "cwd": "/p"}, {}, None, 0)["tmux_pane"] is None
    True
    >>> build_record({"status": "busy", "updatedAt": 0}, {}, None, now_ms=10**12)["stale"]
    True
    """
    cwd = data.get("cwd", "")
    twp = env.get("TERMINAL_WINDOW_PID", "")
    return {
        "host": host,
        "sessionId": data.get("sessionId", ""),
        "pid": data.get("pid"),
        "cwd": cwd,
        "project": Path(cwd).name if cwd else "",
        "status": data.get("status", "unknown"),
        "stale": data.get("status") == "busy"
                 and (now_ms - data.get("updatedAt", now_ms)) > STALE_BUSY_SECS * 1000,
        "terminal_window_pid": int(twp) if twp.isdigit() else None,
        "tmux_pane": env.get("TMUX_PANE") if env.get("TMUX") else None,
        "pane_focused": pane_focused,
    }


def is_focused(rec, local_host, active_pid, ssh_hosts):
    """Are you, right now, looking at this exact session?

    Local: the active window is its terminal AND (no tmux OR its pane is focused).
    Remote: the ssh terminal for that host is the active window AND its remote pane is focused.

    >>> local = {"host": "me", "terminal_window_pid": 42, "pane_focused": None}
    >>> is_focused(local, "me", active_pid=42, ssh_hosts=set())   # my terminal is the active window
    True
    >>> is_focused(local, "me", active_pid=99, ssh_hosts=set())   # some other window is active
    False
    >>> remote = {"host": "pi", "terminal_window_pid": None, "pane_focused": True}
    >>> is_focused(remote, "me", active_pid=1, ssh_hosts={"pi"})  # ssh'd into pi, its pane active
    True
    >>> is_focused(remote, "me", active_pid=1, ssh_hosts=set())   # not looking at pi right now
    False
    """
    pane_ok = rec["pane_focused"] in (None, True)
    if rec["host"] == local_host:
        window_ok = active_pid is not None and active_pid == rec["terminal_window_pid"]
        return window_ok and pane_ok
    return rec["host"] in ssh_hosts and pane_ok


def compute_state(rec, focused):
    """Map a session record + focus to its reported state.

    In: rec — session dict; focused — bool. Out: "running"|"pending"|"idle"|"stale".

    >>> compute_state({"stale": False, "status": "busy"}, focused=False)  # working
    'running'
    >>> compute_state({"stale": False, "status": "idle"}, focused=True)   # you're on it
    'idle'
    >>> compute_state({"stale": False, "status": "idle"}, focused=False)  # needs you
    'pending'
    >>> compute_state({"stale": True, "status": "busy"}, focused=True)    # busy but gone quiet
    'stale'
    """
    if rec["stale"]:
        return "stale"
    if rec["status"] == "busy":
        return "running"
    return "idle" if focused else "pending"


# ───────────────────────────── HOST I/O (reads /proc, tmux, hyprland) ────────────────────────────

def run(cmd, timeout=5):
    # Run a command, return stripped stdout or None on any failure.
    # In: cmd — argv list. Out: str stdout, or None if non-zero/timeout/missing.
    try:
        out = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        return out.stdout.strip() if out.returncode == 0 else None
    except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
        return None


def proc_environ(pid):
    # Read a process's environment (same-user readable).
    # In: pid — int. Out: dict of env vars, or {} if unreadable.
    try:
        raw = Path(f"/proc/{pid}/environ").read_bytes()
    except OSError:
        return {}
    env = {}
    for chunk in raw.split(b"\0"):
        if b"=" in chunk:
            key, _, val = chunk.partition(b"=")
            env[key.decode("utf-8", "replace")] = val.decode("utf-8", "replace")
    return env


def proc_alive(pid):
    # In: pid — int. Out: True if /proc/<pid> exists.
    return Path(f"/proc/{pid}").exists()


def tmux_pane_focused(pane):
    # Whether a tmux pane is the active pane of its session's active window.
    # In: pane — tmux pane id (e.g. "%34"). Out: True/False, or None if unknowable.
    out = run(["tmux", "display-message", "-t", pane, "-p", "#{pane_active}|#{window_active}"])
    if out is None:
        return None
    return out.strip() == "1|1"


def active_window_pid():
    # The pid of the currently focused Hyprland window (local desktop).
    # Out: int pid, or None if no window / no hyprland. Overridable via CLAUDE_MON_ACTIVE_PID.
    override = os.environ.get("CLAUDE_MON_ACTIVE_PID")
    if override is not None:
        return int(override) if override.isdigit() else None
    out = run(["hyprctl", "activewindow", "-j"])
    if not out:
        return None
    try:
        return json.loads(out).get("pid") or None
    except json.JSONDecodeError:
        return None


def ssh_focused_hosts():
    # Hosts whose SSH terminal is the active local window. v1: explicit via env
    # (CLAUDE_MON_SSH_HOSTS_FOCUSED); process-tree detection of the active window's ssh
    # child is the planned upgrade (D4 in the spec). Out: set of host strings.
    raw = os.environ.get("CLAUDE_MON_SSH_HOSTS_FOCUSED", "")
    return {h.strip() for h in raw.split(",") if h.strip()}


def sessions_dir():
    return Path(os.environ.get("CLAUDE_MON_SESSIONS_DIR", str(Path.home() / ".claude/sessions")))


def collect():
    # Gather THIS host's live sessions: the I/O around the pure build_record. Reads the session
    # files, /proc, and tmux; no hyprland reasoning (the active window may be on another host —
    # that's the aggregator's job). Out: list of session dicts.
    now_ms = time.time() * 1000
    out = []
    for path in sorted(sessions_dir().glob("*.json")):
        try:
            data = json.loads(path.read_text())
        except (OSError, json.JSONDecodeError):
            continue
        pid = data.get("pid")
        if pid is None or not proc_alive(pid):
            continue  # stale file from a dead session
        env = proc_environ(pid)
        pane = env.get("TMUX_PANE") if env.get("TMUX") else None
        out.append(build_record(data, env, tmux_pane_focused(pane) if pane else None, now_ms))
    return out


# ───────────────────────────────────── AGGREGATION (local + remote) ──────────────────────────────

def ssh_collect(host):
    # Run `collect` on a remote host over SSH.
    # In: host — hostname. Out: list of session dicts (host field overwritten), or [] on failure.
    ssh_cmd = shlex.split(os.environ.get("CLAUDE_MON_SSH", "ssh"))
    remote_cmd = shlex.split(os.environ.get("CLAUDE_MON_REMOTE_CMD", "claude-mon"))
    out = run(ssh_cmd + [host] + remote_cmd + ["collect"], timeout=20)
    if not out:
        return []
    try:
        recs = json.loads(out)
    except json.JSONDecodeError:
        return []
    for rec in recs:
        rec["host"] = host  # trust the host we asked, not the remote's self-report
    return recs


def snapshot(remotes):
    # Aggregate local + remote sessions and compute each state.
    # In: remotes — list of hostnames to ssh-collect. Out: list of (rec, state) tuples.
    recs = collect() + [r for h in remotes for r in ssh_collect(h)]
    active_pid = active_window_pid()
    ssh_hosts = ssh_focused_hosts()
    return [(rec, compute_state(rec, is_focused(rec, HOST, active_pid, ssh_hosts))) for rec in recs]


# ───────────────────────────────────────── RENDER + CLI ──────────────────────────────────────────

def print_rows(rows):
    # Render snapshot rows to stdout, one per session.
    icon = {"running": "●", "pending": "▲", "idle": "○", "stale": "?"}
    if not rows:
        print("(no live claude sessions)")
        return
    for rec, state in sorted(rows, key=lambda rs: (rs[0]["host"], rs[0]["project"])):
        sid = rec["sessionId"][:8] or "????????"
        print(f"{icon.get(state, '?')} {state:<8} {rec['host']:<16} {rec['project']:<20} {sid}  {rec['cwd']}")


def main():
    parser = argparse.ArgumentParser(description="Claude Code session monitor")
    sub = parser.add_subparsers(dest="cmd", required=True)
    sub.add_parser("collect")
    p_snap = sub.add_parser("snapshot")
    p_snap.add_argument("--remote", action="append", default=[])
    sub.add_parser("selftest")
    args = parser.parse_args()

    if args.cmd == "collect":
        print(json.dumps(collect()))
    elif args.cmd == "snapshot":
        print_rows(snapshot(args.remote))
    elif args.cmd == "selftest":
        selftest()


def selftest():
    # Run the doctests in this file, then render a few fabricated sessions so you can eyeball
    # the output format without needing live Claude sessions. Out: prints results; exits 1 on fail.
    import doctest
    res = doctest.testmod()
    print(f"doctests: {res.attempted - res.failed}/{res.attempted} passed\n")
    print("example rendered output (fabricated sessions, one per state):")
    examples = [  # (record, focused?) — drives running / pending / idle
        (build_record({"sessionId": "a1b2c3d4", "cwd": "/home/me/api", "status": "busy"}, {}, None, 0, "jollof-home"), False),
        (build_record({"sessionId": "e5f6a7b8", "cwd": "/home/me/web", "status": "idle"}, {}, None, 0, "jollof-home"), False),
        (build_record({"sessionId": "99887766", "cwd": "/srv/trading-bot", "status": "idle"}, {}, None, 0, "pi-box"), True),
    ]
    print_rows([(rec, compute_state(rec, focused)) for rec, focused in examples])
    raise SystemExit(1 if res.failed else 0)


if __name__ == "__main__":
    main()
