{ config, modulesPath, nix2container, pkgs, self, ... }:

{
  require = [
    "${modulesPath}/tools/mod-lean-python.nix"
    "${modulesPath}/languages/python-poetry.nix"
    "${modulesPath}/builders/docker-nix2container.nix"
  ];

  name = "test-app";
  src_exclude = [''
    *
    !/test_app.py
    !/pyproject.toml
    !/poetry.lock
  ''];

  lean_python = {
    enable = true;
    package = pkgs.python311;
    configd = true;
    expat = true;
    libffi = true;
    openssl = true;
    zlib = true;
  };

  python = {
    enable = true;
    package = config.out_lean_python;
    inject_app_env = true;
    prefer_wheels = false;
  };

  docker = {
    enable = true;

    # layout of the root directory
    copy_to_root = pkgs.buildEnv {
      name = "root";
      paths = [
        config.out_python
        pkgs.busybox # only for debugging
      ];
      pathsToLink = [ "/bin" ];
    };

    entrypoint = [ "${pkgs.tini}/bin/tini" ];
    command = [ "${config.out_python}/bin/test-app" ];

    # getting permission error on some k8s clusters
    user = "65535:65535";

    # organize the container into 3 layers:
    # - base layer with pythoni, busybox & tini
    # - layer with application dependencies
    # - our application
    layers = with nix2container; let
      layer-1 = buildLayer {
        deps = with pkgs; [
          busybox
          config.out_lean_python
          tini
        ];
      };
      layer-2 = buildLayer {
        deps = config.out_python.propagatedBuildInputs;
        layers = [
          layer-1
        ];
      };
    in [
      layer-1
      layer-2
    ];
  };
}
