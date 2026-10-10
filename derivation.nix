{ pkgs }:
pkgs.python313Packages.buildPythonPackage rec {
  pname = "korpcal";
  version = "0.0.1";
  format = "pyproject";
  src = ./src;
  propagatedBuildInputs = [
    pkgs.python313Packages.apscheduler
    pkgs.python313Packages.flask
    pkgs.python313Packages.gunicorn
    pkgs.python313Packages.icalendar
  ];
  build-system = [
    pkgs.python313Packages.setuptools
  ];
  buildInputs = [
  ];
}
