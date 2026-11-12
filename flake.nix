{
  description = "A Nix flake for sendspin-cpp-cli";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      # Pin upstream sources
      sendspin-cpp-cli = pkgs.fetchFromGitHub {
        owner = "Sendspin";
        repo = "sendspin-cpp-cli";
        rev = "b0e65fc9d64575271f0226519704c27ac956642a";
        hash = "sha256-Y/y9ugNjDNbWfE3r4pjH1L2zjNf1pGmITdOK/YBVuLY=";
      };
      sendspin-cpp = pkgs.fetchFromGitHub {
        owner = "Sendspin";
        repo = "sendspin-cpp";
        rev = "b0fcf5bb369b470ddc4987280c19f0919e9a9084";
        hash = "sha256-QqXYJF7AYzLniv0CfpQWKkFWvW6vtnTlX25bJzKH7Z8=";
      };
      arduinojson = pkgs.fetchFromGitHub {
        owner = "bblanchon";
        repo = "ArduinoJson";
        rev = "32520135092970120a5ac165cf45f48e658c421d";
        hash = "sha256-CvwL3FDsbQGLkZFC3Z/RWeiT9tO+7ZRpT65YUdRT5dQ=";
      };
      ixwebsocket = pkgs.fetchFromGitHub {
        owner = "machinezone";
        repo = "IXWebSocket";
        rev = "64fae7676bd8fe31f7cb4bcde7a6841892dad65e";
        hash = "sha256-2QWIpLVIs2vGuMEhewDyihYdDQBz7SsOtfZ6pE67j2Q=";
      };
      noise-c = pkgs.fetchFromGitHub {
        owner = "esphome-libs";
        repo = "noise-c";
        rev = "a1e08809a1b8f65cd91765ba7d68a6d00648ad61";
        hash = "sha256-5bu3Vh+8w4cVuU9n7oc20uhswJgxVtIeHoIzTjAr/Xo=";
      };
      # micro-flac and micro-opus need their git submodules
      micro-flac = pkgs.fetchFromGitHub {
        owner = "esphome-libs";
        repo = "micro-flac";
        rev = "f9c27d4d0166021db977d7fc37d205b21d81e9f2";
        fetchSubmodules = true;
        hash = "sha256-XnwYlGoYk3ra7hg/ni7Sy5EtSKzil6386OGoXY7j5MI=";
      };
      micro-opus = pkgs.fetchFromGitHub {
        owner = "esphome-libs";
        repo = "micro-opus";
        rev = "3e9ce44c56ab8007261d68c511f0162599542aa2";
        fetchSubmodules = true;
        hash = "sha256-OV5J8UgL81Rerotu2zjpR5LQfqnYb0e+KkFutP1INqo=";
      };
    in
    {
      packages.${system}.default = pkgs.stdenv.mkDerivation {
        pname = "sendspin-cpp-cli";
        version = "0.4.0";
        src = sendspin-cpp-cli;

        nativeBuildInputs = with pkgs; [
          cmake
          pkg-config
          gnumake
        ];

        buildInputs = with pkgs; [
          alsa-lib
          avahi-compat
          portaudio
          pulseaudio
          pipewire
          openssl
        ];

        cmakeFlags = [
          "-DSENDSPIN_CLI_BUILD_TESTS=OFF"
          "-DFETCHCONTENT_SOURCE_DIR_SENDSPIN=${sendspin-cpp}"
          "-DFETCHCONTENT_SOURCE_DIR_ARDUINOJSON=${arduinojson}"
          "-DFETCHCONTENT_SOURCE_DIR_IXWEBSOCKET=${ixwebsocket}"
          "-DFETCHCONTENT_SOURCE_DIR_NOISE_C=${noise-c}"
        ];

        # micro-flac and micro-opus need writable source dirs (they apply patches
        # to their bundled submodules during CMake configure). Copy from the
        # read-only nix store to a writable location.
        preConfigure = ''
          cp -r ${micro-flac} micro-flac-writable
          chmod -R u+w micro-flac-writable
          cp -r ${micro-opus} micro-opus-writable
          chmod -R u+w micro-opus-writable
          cmakeFlagsArray+=("-DFETCHCONTENT_SOURCE_DIR_MICRO_FLAC=$PWD/micro-flac-writable")
          cmakeFlagsArray+=("-DFETCHCONTENT_SOURCE_DIR_MICRO_OPUS=$PWD/micro-opus-writable")
        '';

        installPhase = ''
          runHook preInstall
          mkdir -p $out/bin
          find . -name sendspin-cli -type f -executable -exec cp {} $out/bin/ \;
          runHook postInstall
        '';
      };

      apps.${system}.default = {
        type = "app";
        program = "${self.packages.${system}.default}/bin/sendspin-cli";
      };

      devShells.${system}.default = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [
          cmake
          pkg-config
          gnumake
        ];
        buildInputs = with pkgs; [
          alsa-lib
          avahi-compat
          portaudio
          pulseaudio
          pipewire
          openssl
        ];
      };
    };
}