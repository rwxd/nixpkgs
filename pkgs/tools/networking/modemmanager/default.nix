{ lib, stdenv, fetchurl
, fetchpatch
, glib, udev, libgudev, polkit, ppp, gettext, pkg-config, python3
, libmbim, libqmi, systemd, vala, gobject-introspection, dbus
}:

stdenv.mkDerivation rec {
  pname = "modemmanager";
  version = "1.18.10";

  src = fetchurl {
    url = "https://www.freedesktop.org/software/ModemManager/ModemManager-${version}.tar.xz";
    sha256 = "sha256-FiVfginu6y3+y43RNwNg1G8QFeyF5vulwcvZ9DcdZes=";
  };

  patches = [
    # Fix tests with GLib 2.73.2
    # https://gitlab.freedesktop.org/mobile-broadband/ModemManager/-/issues/601
    (fetchpatch {
      url = "https://gitlab.freedesktop.org/mobile-broadband/ModemManager/-/commit/79a5a4eed2189ea87d25cbe00bc824a2572cad66.patch";
      sha256 = "egGXkCzAMyqPjeO6ro23sdTddTDEGJUkV7rH8sSlSGE=";
    })
    (fetchpatch {
      url = "https://gitlab.freedesktop.org/mobile-broadband/ModemManager/-/commit/51a333cd9a6707de7c623fd4c94cb6032477572f.patch";
      sha256 = "1XyJ0GBmpBRwnsKPI4i/EBrF7W08HelL/PMDwmlQWcw=";
    })
  ];

  nativeBuildInputs = [ vala gobject-introspection gettext pkg-config ];

  buildInputs = [ glib udev libgudev polkit ppp libmbim libqmi systemd ];

  installCheckInputs = [
    python3 python3.pkgs.dbus-python python3.pkgs.pygobject3
  ];

  configureFlags = [
    "--with-polkit"
    "--with-udev-base-dir=${placeholder "out"}/lib/udev"
    "--with-dbus-sys-dir=${placeholder "out"}/share/dbus-1/system.d"
    "--with-systemdsystemunitdir=${placeholder "out"}/etc/systemd/system"
    "--sysconfdir=/etc"
    "--localstatedir=/var"
    "--with-systemd-suspend-resume"
    "--with-systemd-journal"
  ];

  postPatch = ''
    patchShebangs tools/test-modemmanager-service.py
  '';

  # In Nixpkgs g-ir-scanner is patched to produce absolute paths, and
  # that interferes with ModemManager's tests, causing them to try to
  # load libraries from the install path, which doesn't usually exist
  # when `make check' is run.  So to work around that, we run it as an
  # install check instead, when those paths will have been created.
  doInstallCheck = true;
  preInstallCheck = ''
    export G_TEST_DBUS_DAEMON="${dbus.daemon}/bin/dbus-daemon"
    patchShebangs tools/tests/test-wrapper.sh
  '';
  installCheckTarget = "check";

  enableParallelBuilding = true;

  meta = with lib; {
    description = "WWAN modem manager, part of NetworkManager";
    homepage = "https://www.freedesktop.org/wiki/Software/ModemManager/";
    license = licenses.gpl2Plus;
    maintainers = teams.freedesktop.members;
    platforms = platforms.linux;
  };
}
