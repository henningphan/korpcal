{ pkgs }:
pkgs.python313Packages.buildPythonPackage rec {
  pname = "stadcal";
  version = "0.0.1";
  format = "pyproject";
  src = ./src;
  propagatedBuildInputs = [
    pkgs.python313Packages.apscheduler
    pkgs.python313Packages.flask
    pkgs.python313Packages.gunicorn
    pkgs.python313Packages.icalendar
    pkgs.python313Packages.playwright
    pkgs.firefox
  ];
  build-system = [
    pkgs.python313Packages.setuptools
  ];
  buildInputs = [
  ];
}
