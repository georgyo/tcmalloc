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

          # Build abseil-cpp as static libraries so we can bundle them
          # into the tcmalloc static lib without exposing abseil symbols.
          abseil-cpp-static = pkgs.abseil-cpp.overrideAttrs (old: {
            cmakeFlags = (old.cmakeFlags or []) ++ [
              "-DBUILD_SHARED_LIBS=OFF"
            ];
          });
        in
        {
          default = self.packages.${system}.tcmalloc;

          tcmalloc = pkgs.stdenv.mkDerivation {
            pname = "tcmalloc";
            version = "0-unstable";

            src = self;

            nativeBuildInputs = with pkgs; [
              cmake
              pkg-config
            ];

            buildInputs = [
              abseil-cpp-static
            ] ++ (with pkgs; [
              gtest
              protobuf
              gbenchmark
              re2
            ]);

            # Patch build files to:
            # 1. Remove fuzztest (not in nixpkgs, only needed for fuzz tests)
            # 2. Remove testing subdirectory (depends on fuzztest)
            # 3. Add explicit find_package(re2) since it's no longer a transitive dep
            # 4. Make test/binary functions no-ops so test targets in library
            #    CMakeLists.txt don't fail during configure
            postPatch = ''
              substituteInPlace CMakeLists.txt \
                --replace-fail 'FetchContent_Declare(
  fuzztest
  GIT_REPOSITORY https://github.com/google/fuzztest.git
  GIT_TAG        main
  FIND_PACKAGE_ARGS NAMES fuzztest
)
FetchContent_MakeAvailable(fuzztest)' "" \
                --replace-fail 'add_subdirectory(tcmalloc/testing)' "" \
                --replace-fail 'enable_testing()' "" \
                --replace-fail 'include(FetchContent)' 'include(FetchContent)
find_package(re2 REQUIRED)'

              # Make test/binary helper functions no-ops so cmake configure
              # succeeds without test dependencies
              substituteInPlace tcmalloc/tcmalloc_helpers.cmake \
                --replace-fail 'function(tcmalloc_cc_test)' 'function(tcmalloc_cc_test)
  return()' \
                --replace-fail 'function(tcmalloc_cc_binary)' 'function(tcmalloc_cc_binary)
  return()'

              # Also no-op the variant test/binary functions
              substituteInPlace tcmalloc/tcmalloc_variants.cmake \
                --replace-fail 'function(tcmalloc_cc_test_variants)' 'function(tcmalloc_cc_test_variants)
  return()' \
                --replace-fail 'function(tcmalloc_cc_binary_variants)' 'function(tcmalloc_cc_binary_variants)
  return()'
            '';

            cmakeFlags = [
              "-DCMAKE_BUILD_TYPE=Release"
              "-DFETCHCONTENT_FULLY_DISCONNECTED=ON"
            ];

            # Only build the main tcmalloc library, not tests
            buildFlags = [
              "tcmalloc_tcmalloc"
            ];

            installPhase = ''
              runHook preInstall

              mkdir -p $out/lib $out/include/tcmalloc

              # Install the main static library
              cp tcmalloc/libtcmalloc_tcmalloc.a $out/lib/libtcmalloc.a

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
