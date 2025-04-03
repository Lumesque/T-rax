{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-20.03";
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
  };

  outputs = { self, nixpkgs, flake-utils }: 
  flake-utils.lib.eachDefaultSystem (system:
  let
    pkgs = (import nixpkgs {
      inherit system;
      config = {
        permittedInsecurePackages = [ "python-2.7.18.8" "python-2.7.18.8-env" ];
      };
    });
    asteval = {
      name = "asteval";
      pname = "asteval";
      pyproject = false;
      src = pkgs.fetchFromGitHub {
        owner = "lmfit";
        repo = "asteval";
        rev = "0.9.17";
        hash = "sha256-IyhPsTJ78xJ8wWvZhBPrCMle0Tpmi2kbZo9TtRuq9rI=";
      };
      buildInputs = [(pkgs.python27Packages.pytest)];
    };
    pyshortcuts = {
      name = "pyshortcuts";
      pname = "pyshortcuts";
      pyproject = false;
      src = pkgs.fetchFromGitHub {
        owner = "newville";
        repo = "pyshortcuts";
        rev = "1.7.1";
        hash = "sha256-kb2IawULhFRT4HacJJtfMypRyS1p6v5Z6AMkklVFtfk=";
      };
      buildInputs = [(pkgs.python27Packages.six)];
    };
    py27Dep = name: (pkgs.python27Packages.${name});
    lmfit-deps = [
      (pkgs.python27Packages.buildPythonPackage asteval)
      (pkgs.python27Packages.buildPythonPackage pyshortcuts)
      (py27Dep "scipy")
      (py27Dep "six")
      (py27Dep "uncertainties")
    ];
    lmfit-py = {
      name = "lmfit";
	  pname = "lmfit";
	  pyproject = false;
	  src = pkgs.fetchFromGitHub {
        owner = "lmfit";
        repo = "lmfit-py";
        rev = "0.9.15";
        hash = "sha256-qm/9JfZm8LONpSW6EMdfiVJsbWFFxZ0C/k8bhgp/SJ4=";
	  };
	  nativeBuildInputs = [];
	  buildInputs = [(pkgs.python27Packages.pytest)] ++ lmfit-deps;
	  propagatedBuildInputs = lmfit-deps;
    };

    python-packages = [(pkgs.python27.withPackages (pp: [
     pp.qtpy
     pp.numpy
     pp.scipy
     pp.pyqtgraph
     pp.dateutil
     pp.h5py
     pp.mock
     (pkgs.python27Packages.buildPythonPackage lmfit-py)
    ]))];
    app = pkgs.python27Packages.buildPythonApplication {
      name = "T-Rax";
      pname = "T-Rax";
      src = ./.;
      pyproject = false;
      nativeBuildInputs = python-packages;
      propagatedBuildInputs = python-packages;
      dontUseSetuptoolsCheck = true;
      patches = [
        ./patches/qt-fix.patch
        ./patches/setup-fix.patch
        ./patches/version-fix.patch
      ];
    };
    python-build-pkgs = [ pkgs.qt5.full app ];
  in
  {
    packages.default = pkgs.symlinkJoin {
        name = "nix-shell-dev-env";
        paths = python-packages ++ [pkgs.cowsay pkgs.python27Packages.versioneer] ++ python-build-pkgs ;
    };

    devShells.default = pkgs.mkShell {
      packages = python-packages ++ [pkgs.cowsay] ++ python-build-pkgs;
    };
  });
}
