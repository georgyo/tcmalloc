{
  description = "TCMalloc - Google's fast memory allocator";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = self.packages.${system}.tcmalloc;

          tcmalloc = pkgs.stdenv.mkDerivation {
            pname = "tcmalloc";
            version = "4.0.0";

            src = self;

            nativeBuildInputs = with pkgs; [
              cmake
            ];

            buildInputs = with pkgs; [
              abseil-cpp
              gtest
              protobuf
              gbenchmark
              re2
            ];

            cmakeFlags = [
              "-DCMAKE_BUILD_TYPE=Release"
              "-DFETCHCONTENT_FULLY_DISCONNECTED=ON"
            ];

            buildFlags = [
              "tcmalloc_shared"
              "tcmalloc_bundled"
            ];

            installPhase = ''
              runHook preInstall

              mkdir -p $out/lib $out/include/tcmalloc

              # Install shared library
              cp tcmalloc/libtcmalloc.so* $out/lib/
              # Fix symlinks to be relative
              cd $out/lib
              rm -f libtcmalloc.so libtcmalloc.so.4
              ln -s libtcmalloc.so.4.0.0 libtcmalloc.so.4
              ln -s libtcmalloc.so.4 libtcmalloc.so
              cd -

              # Install bundled static library
              cp tcmalloc/libtcmalloc_bundled.a $out/lib/

              # Install public headers
              cd $src
              cp tcmalloc/malloc_extension.h $out/include/tcmalloc/
              cp tcmalloc/malloc_hook.h $out/include/tcmalloc/
              cp tcmalloc/malloc_tracing_extension.h $out/include/tcmalloc/
              cp tcmalloc/alloc_at_least.h $out/include/tcmalloc/

              runHook postInstall
            '';

            meta = with pkgs.lib; {
              description = "Google's fast memory allocator";
              homepage = "https://github.com/google/tcmalloc";
              license = licenses.asl20;
              platforms = platforms.linux;
            };
          };
        });

      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            inputsFrom = [ self.packages.${system}.tcmalloc ];
          };
        });
    };
}
