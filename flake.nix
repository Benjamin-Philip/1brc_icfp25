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

        ar5iv-setup = ''
          mkdir -p out
          cp -rn ${ar5iv-bindings} out/ar5iv-bindings
        '';

        misc = with pkgs; [
          bash # For latexmk's `-usepretex`
          coreutils # For `env` and `mktemp`
          glibcLocales # For elixir and LaTeX
          gnumake
          perlPackages.LaTeXML
        ];

        buildInputs = [
          tex
          ar5iv-bindings
        ] ++ misc;

        nixfmt = nixpkgs.legacyPackages.${system}.nixfmt-rfc-style;

        erlang = pkgs.beam.packagesWith pkgs.beam.interpreters.erlang_27;
        act = if builtins.getEnv "CI" != "true" then [ pkgs.act ] else [ ];
        devInputs = [
          erlang.elixir
          nixfmt
        ] ++ act ++ buildInputs;

      in
      rec {
        packages = {
          default = pkgs.stdenvNoCC.mkDerivation rec {
            inherit buildInputs;

            name = "paper";
            src = self;
            phases = [
              "unpackPhase"
              "buildPhase"
              "installPhase"
            ];
            buildPhase = ''
              runHook preBuild
              export PATH="${pkgs.lib.makeBinPath buildInputs}";

              ${ar5iv-setup}

              env SOURCE_DATE_EPOCH=${toString self.lastModified} \
                  HOME=$(mktemp -d) make

              runHook postBuild
            '';
            installPhase = ''
              runHook preInstall
              mkdir -p $out
              cp -r out $out
              runHook postInstall
            '';
          };
        };

        devShells = {
          default = pkgs.mkShellNoCC {
            buildInputs = devInputs;
            shellHook = ''
              # this allows mix to work on the local directory
              mkdir -p .nix-mix .nix-hex
              export MIX_HOME=$PWD/.nix-mix
              export HEX_HOME=$PWD/.nix-mix

              # make hex from Nixpkgs available
              # `mix local.hex` will install hex into MIX_HOME and should take precedence
              export MIX_PATH="${erlang.hex}/lib/erlang/lib/hex/ebin"
              export PATH=$MIX_HOME/bin:$HEX_HOME/bin:$PATH

              # keep your shell history in iex
              export ERL_AFLAGS="-kernel shell_history enabled"

              # correct date in LaTeX
              export SOURCE_DATE_EPOCH=${toString self.lastModified}

              ${ar5iv-setup}
              chmod -R +w out/ar5iv-bindings
            '';
          };
        };

        formatter = nixfmt;
      }
    );
}
