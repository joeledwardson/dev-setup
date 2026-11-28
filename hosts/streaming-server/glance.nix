{ ... }:

# a reading page, separate from homepage.nix: homepage answers "where are my
# services", this answers "what's new". widget options are documented at
# https://github.com/glanceapp/glance/blob/v0.8.8/docs/configuration.md
{
  services.glance = {
    enable = true;
    settings = {
      server = {
        # only caddy talks to it, see news.joels-netflix.com in caddy.nix
        host = "127.0.0.1";
        # port from 9000 + crc32("glance") % 900
        port = 9026;
        # trust caddy's X-Forwarded-* headers
        proxied = true;
      };
      pages = [
        {
          name = "News";
          columns = [
            {
              size = "full";
              widgets = [
                {
                  type = "rss";
                  title = "People";
                  style = "detailed-list";
                  # practitioners writing about agents, testing and evals, not "AI news".
                  # dex horthy / humanlayer isn't here because the blog has no feed
                  feeds = [
                    # entries only; /atom/everything/ adds every link and quote, several a day
                    { url = "https://simonwillison.net/atom/entries/"; title = "Simon Willison"; }
                    { url = "https://newsletter.kentbeck.com/feed"; title = "Kent Beck"; }
                    { url = "https://hamel.dev/index.xml"; title = "Hamel Husain"; }
                    { url = "https://eugeneyan.com/rss/"; title = "Eugene Yan"; }
                  ];
                }
              ];
            }
            {
              size = "full";
              widgets = [
                { type = "hacker-news"; }
                {
                  type = "lobsters";
                  # glance always sorts tag-filtered lobsters by hot
                  tags = [ "ai" "practices" "testing" ];
                }
              ];
            }
            {
              size = "small";
              widgets = [
                {
                  # one line per repo: the latest release, prereleases skipped by default
                  type = "releases";
                  repositories = [
                    "element-hq/element-x-android"
                    "element-hq/element-x-ios"
                    "zed-industries/zed"
                  ];
                }
              ];
            }
          ];
        }
      ];
    };
  };
}
