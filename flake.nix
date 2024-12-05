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

        misc = with pkgs; [
          coreutils # For `env` and `mktemp`
          gnumake # For building the project
          bash # For latexmk's `-usepretex`
        ];

        inputs = [ tex ] ++ misc;
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
              env HOME=$(mktemp -d) SOURCE_DATE_EPOCH=${toString self.lastModified} \
                  make out/paper.pdf
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
