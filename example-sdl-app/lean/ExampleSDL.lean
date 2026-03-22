import SDLBindings

def squareSize : Float := 120.0

def tickDt : Float := 1.0 / 60.0

def maxFrameDt : Float := 0.25

def warmupFrames : UInt32 := 100

structure AppState where
  frame : UInt32
  x : Float
  y : Float
  dx : Float
  dy : Float
  maxX : Float
  maxY : Float
  accumulator : Float
deriving Inhabited

def bounce (pos vel limit dt : Float) : Float × Float :=
  let next := pos + vel * dt
  if next < 0.0 then
    (-next, -vel)
  else if next > limit then
    (limit - (next - limit), -vel)
  else
    (next, vel)

initialize appState : IO.Ref AppState <- IO.mkRef {
  frame := 0
  x := 0.0
  y := 0.0
  dx := 0.0
  dy := 0.0
  maxX := 0.0
  maxY := 0.0
  accumulator := 0.0
}

@[export sdlInit]
def sdlInit : IO Unit := do
  SDL.initVideo
  SDL.setupFullscreenWindowAndRenderer "Lean SDL Example"
  let width ← SDL.getWindowWidth
  let height ← SDL.getWindowHeight
  let maxX := max 0.0 (width.toFloat - squareSize)
  let maxY := max 0.0 (height.toFloat - squareSize)
  appState.set {
    frame := 0
    x := 0.0
    y := 0.0
    dx := 240.0
    dy := 120.0
    maxX := maxX
    maxY := maxY
    accumulator := 0.0
  }

@[export sdlIterate]
def sdlIterate : IO Unit := do
  let state ← appState.get
  let mut stepped := state
  if state.frame < warmupFrames then
    stepped := { state with frame := state.frame + 1, accumulator := 0.0 }
  else
    let frameDt := min (← SDL.getFrameTime) maxFrameDt
    let mut remaining := state.accumulator + frameDt
    while remaining >= tickDt do
      let (x, dx) := bounce stepped.x stepped.dx stepped.maxX tickDt
      let (y, dy) := bounce stepped.y stepped.dy stepped.maxY tickDt
      stepped := {
        frame := stepped.frame + 1
        x := x
        y := y
        dx := dx
        dy := dy
        maxX := stepped.maxX
        maxY := stepped.maxY
        accumulator := remaining - tickDt
      }
      remaining := remaining - tickDt
    stepped := { stepped with accumulator := remaining }
  SDL.setRenderDrawColor 255 255 255 255
  SDL.renderClear
  SDL.setRenderDrawColor 0 0 0 255
  SDL.renderFillRect
    stepped.x
    stepped.y
    squareSize
    squareSize
  SDL.renderPresent
  appState.set stepped

@[export sdlQuit]
def sdlQuit : IO Unit := do
  SDL.shutdown
