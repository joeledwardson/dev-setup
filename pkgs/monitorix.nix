# Monitorix — not in nixpkgs, so fetched from its GitHub release tag.
#
# It is pure Perl (nothing compiles), so "packaging" it means: copy the tree
# into the store, and wrap the two entry points so they can find both Monitorix's
# own lib/ and the CPAN modules its graph modules pull in at runtime. Missing a
# Perl module shows up as a broken individual graph rather than a startup
# failure, which is why the dependency list below is generous.
{ lib, stdenv, fetchFromGitHub, makeWrapper, perl, perlPackages, rrdtool }:

let
  perlDeps = with perlPackages; [
    ConfigGeneral
    CGI
    DBI
    HTTPServerSimple # provides HTTP::Server::Simple::CGI for the built-in httpd
    LWP
    MIMELite
    NetIP
    XMLLibXML
    XMLSimple
    rrdtool # provides the RRDs perl bindings
  ];
in
stdenv.mkDerivation (finalAttrs: {
  pname = "monitorix";
  version = "3.16.0";

  src = fetchFromGitHub {
    owner = "mikaku";
    repo = "Monitorix";
    tag = "v${finalAttrs.version}";
    hash = "sha256-ESY5k0b65OR5Dg4h00uZNlA3EGmimIyG+wL6WNsko+I=";
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ perl ] ++ perlDeps;

  # The upstream Makefile installs into /etc, /usr and /var, which does not work
  # in a sandboxed build. Installing by hand is shorter than patching it.
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib/monitorix $out/share/monitorix
    cp -r lib/* $out/lib/monitorix/
    cp -r css reports logo_top.png logo_bot.png monitorixico.png $out/share/monitorix/
    cp monitorix.conf $out/share/monitorix/monitorix.conf.example

    install -Dm755 monitorix     $out/bin/monitorix
    install -Dm755 monitorix.cgi $out/share/monitorix/monitorix.cgi

    # The CGI does not take a --config flag. It reads a pointer file named
    # 'monitorix.conf.path' sitting next to itself and uses whatever path is
    # inside. Because makeWrapper leaves the real script in the store, that
    # lookup resolves to this directory — so the pointer has to be baked in
    # here, aimed at a stable location the NixOS module then populates.
    echo /etc/monitorix/monitorix.conf > $out/share/monitorix/monitorix.conf.path

    for prog in $out/bin/monitorix $out/share/monitorix/monitorix.cgi; do
      wrapProgram $prog \
        --prefix PERL5LIB : "$out/lib/monitorix:${perlPackages.makeFullPerlPath perlDeps}" \
        --prefix PATH : "${lib.makeBinPath [ rrdtool ]}"
    done

    runHook postInstall
  '';

  meta = {
    description = "Lightweight system monitoring tool that graphs to RRD and serves static HTML";
    homepage = "https://www.monitorix.org/";
    license = lib.licenses.gpl2Only;
    platforms = lib.platforms.linux;
    mainProgram = "monitorix";
  };
})
