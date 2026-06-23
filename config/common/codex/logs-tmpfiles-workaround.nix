{
  # Work around excessive Codex log I/O by placing the sqlite log in runtime storage.
  systemd.user.tmpfiles.rules = [
    "d %h/.codex 0700 - - -"
    "d %t/codex-logs 0700 - - -"
    "f %t/codex-logs/logs_2.sqlite 0600 - - -"
    "L %h/.codex/logs_2.sqlite - - - - %t/codex-logs/logs_2.sqlite"
  ];
}
