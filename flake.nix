{
  description = "Rust + Leptos + Axum + SQLite + Tailwindcss + DaisyUI + Nix + Tauri";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs_daisyui.url = "github:NixOS/nixpkgs/dc763d353cdf5c5cd7bf2c7af4b750960e66cce7";
    nixpkgs_tauri.url = "github:DaraJKong/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs_daisyui,
    nixpkgs_tauri,
    flake-utils,
    rust-overlay,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      overlays = [(import rust-overlay)];

      pkgs = import nixpkgs {
        inherit system overlays;
      };
      pkgs_daisyui = import nixpkgs_daisyui {
        inherit system;
      };
      pkgs_tauri = import nixpkgs_tauri {
        inherit system;
      };

      my-tailwindcss = pkgs.nodePackages.tailwindcss.overrideAttrs (oa: {
        plugins = [pkgs_daisyui.daisyui];
      });

      # Required by tauri
      libraries = with pkgs; [
        webkitgtk
        gtk3
        cairo
        gdk-pixbuf
        glib
        dbus
        openssl_3
        librsvg
      ];

      packages = with pkgs; [
        curl
        wget
        pkg-config
        dbus
        openssl_3
        glib
        gtk3
        libsoup_3
        webkitgtk_4_1
        librsvg
      ];
    in
      with pkgs; {
        devShells.default = mkShell {
          shellHook = ''
            export PKG_CONFIG_PATH="${pkgs.openssl.dev}/lib/pkgconfig";
            export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath libraries}:$LD_LIBRARY_PATH
            export XDG_DATA_DIRS=${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:$XDG_DATA_DIRS
          '';
          nativeBuildInputs = [
            pkg-config
          ];
          buildInputs =
            [
              git
              openssl
              (rust-bin.stable.latest.default.override {
                extensions = ["rust-src" "rust-std" "rust-analyzer" "rustfmt" "clippy"];
                targets = ["x86_64-unknown-linux-gnu" "wasm32-unknown-unknown"];
              })
              binaryen
              trunk
              cargo-leptos
              leptosfmt
              sqlite
              sqlx-cli
              nil
              alejandra
              statix
              deadnix
              taplo
              sass
              my-tailwindcss
              tailwindcss-language-server
              (pkgs_tauri.cargo-tauri-beta)
              (pkgs_tauri.cargo-create-tauri-app)
            ]
            ++ packages;
        };
      });
}
