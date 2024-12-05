{
  description = "1brc_icfp25";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        overlays = [ ];
        pkgs = import nixpkgs { inherit overlays system; };

        tex = pkgs.texliveBasic.withPackages (
          ps: with ps; [
            collection-fontsrecommended
            collection-fontsextra
            collection-latexextra
            collection-latexrecommended
            collection-metapost
            collection-luatex
            acmart
            latexmk
          ]
        );

        ar5iv-bindings = builtins.fetchTarball {
          url = "https://github.com/dginev/ar5iv-bindings/archive/refs/tags/0.3.0.tar.gz";
          sha256 = "0isqy8b16py0apgjbl7bdjph9ilhmm479i2g0mlzr2rgai308gl7";
        };

        misc = with pkgs; [
          bash # For latexmk's `-usepretex`
          coreutils # For `env` and `mktemp`
          gnumake
          perlPackages.LaTeXML
        ];

        inputs = [
          tex
          ar5iv-bindings
        ] ++ misc;
      in
      rec {
        packages = {
          paper = pkgs.stdenvNoCC.mkDerivation rec {
            name = "paper";
            src = self;
            buildInputs = inputs;
            phases = [
              "unpackPhase"
              "buildPhase"
              "installPhase"
            ];
            buildPhase = ''
              export PATH="${pkgs.lib.makeBinPath buildInputs}";

              mkdir -p out
              cp -r ${ar5iv-bindings} out/ar5iv-bindings

              env SOURCE_DATE_EPOCH=${toString self.lastModified} \
                  HOME=$(mktemp -d) make
            '';
            installPhase = ''
              mkdir -p $out
              cp -r out $out
            '';
          };
        };
        defaultPackage = packages.paper;
        formatter = nixpkgs.legacyPackages.${system}.nixfmt-rfc-style;
      }
    );
}
