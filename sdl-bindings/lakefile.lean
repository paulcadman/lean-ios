import Lake

open Lake DSL System

package sdl_bindings where
  srcDir := "lean"

target sdlBindingsO pkg : FilePath := do
  let oFile := pkg.buildDir / "c" / "LeanSDLBindings.o"
  let srcJob ← inputTextFile <| pkg.dir / "native" / "LeanSDLBindings.c"
  let sdlInclude := pkg.dir / ".." / "third-party" / "SDL" / "include"
  let sdlTtfInclude := pkg.dir / ".." / "third-party" / "SDL_ttf" / "include"
  let resvgInclude := pkg.dir / ".." / "third-party" / "resvg" / "crates" / "c-api"
  let weakArgs := #[
    "-I", s!"{pkg.dir / "native"}",
    "-I", s!"{sdlInclude}",
    "-I", s!"{sdlTtfInclude}",
    "-I", s!"{resvgInclude}"
  ]
  buildLeanO oFile srcJob weakArgs

lean_lib SDLBindings where
  roots := #[`SDLBindings]
  moreLinkObjs := #[sdlBindingsO]
  defaultFacets := #[`static]
