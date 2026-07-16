{ pkgsFrom, ... }:
{
  services.gpg-agent.pinentry.package = pkgsFrom.self.pinentry-auto;
}
