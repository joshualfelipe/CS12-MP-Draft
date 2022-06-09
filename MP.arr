use context essentials2021

#|

    [/] Egg launching
    [/] Platform placement and movement
    [/] Platform landing
    [/] Lives and game over
    [/] Next stage panning

|#

import reactors as R
import image as I

### CUSTOM DATA DEFINITION ###

data GameStatus:
  | ongoing
  | transitioning # ticks-left may be the number of ticks left in the transition period
  | game-over
end

data PlatformLevel:
  | top-lvl
  | middle-lvl
  | bottom-lvl
end

type Platform = {
  x :: Number, # x is at center
  y :: Number, # y is at center
  dx :: Number,
  dy :: Number
}

type Egg = {
  x :: Number, # x is at center
  y :: Number, # y is at center
  dx :: Number,
  dy :: Number,
  ay :: Number,
  is-airborne :: Boolean,
}

type State = {
  game-status :: GameStatus,
  egg :: Egg,
  top-platform :: Platform,
  middle-platform :: Platform,
  bottom-platform :: Platform,
  pre-platform-1 :: Platform,
  pre-platform-2 :: Platform,
  other-platforms :: List<Platform>,
  current-platform :: PlatformLevel,
  score :: Number,
  lives :: Number,
}

### CONSTANTS ###

FPS = 60

SCREEN-WIDTH = 300
SCREEN-HEIGHT = 500

A-DUE-TO-G = 0.5

EGG-RADIUS = 20
EGG-COLOR = "peach-puff"
EGG-JUMP-DY = -13.5

PLATFORM-WIDTH = 60
PLATFORM-HEIGHT = 10
PLATFORM-COLOR = "red"

TOP-PLATFORM-Y = 125
MIDDLE-PLATFORM-Y = 250
BOTTOM-PLATFORM-Y = 375

DEFAULT-HIDDEN-PLATFORM = {x: 0, y: -5, dx: 0, dy:0}

TRANSITION-DY = 1
MAX-PLATFORM-SPEED = 5

DEFAULT-NUM-LIVES = 12



### DRAW ###

fun draw-platform(platform :: Platform, img :: Image) -> Image:
  doc: " Draws a specific platform "

  platform-img = rectangle(PLATFORM-WIDTH, PLATFORM-HEIGHT, "solid", PLATFORM-COLOR)
  I.place-image(platform-img, platform.x, platform.y, img)
end

fun draw-score(state :: State, img :: Image) -> Image:
  doc: " Draws the game score "

  text-img = text(num-to-string(state.score), 28, "black")
  I.place-image(text-img, SCREEN-WIDTH / 2, SCREEN-HEIGHT / 15, img)
end

fun draw-lives(state :: State, img :: Image) -> Image:
  doc: " Draws the player's remaining lives "

  text-img = text("Lives: " + num-to-string(state.lives), 18, "black")
  I.place-image(text-img, (8.65 * SCREEN-WIDTH) / 10, SCREEN-HEIGHT / 25, img)
end

fun draw-game-over(state :: State, img :: Image) -> Image:
  doc: " Draws the game-over text "

  cases (GameStatus) state.game-status:
    | ongoing => img
    | transitioning => img
    | game-over =>
      text-img = text("GAME OVER", 48, "black")
      I.overlay(text-img, img)
  end
end

fun draw-handler(state :: State) -> Image:
  doc: " Draws all the elements used "

  canvas = empty-color-scene(SCREEN-WIDTH, SCREEN-HEIGHT, "light-blue")
  canvas
    ^ draw-platform(state.top-platform, _)
    ^ draw-platform(state.middle-platform, _)
    ^ draw-platform(state.bottom-platform, _)
    ^ draw-platform(state.pre-platform-1, _)
    ^ draw-platform(state.pre-platform-2, _)
    ^ draw-egg(state.egg, _)
    ^ draw-score(state, _)
    ^ draw-lives(state, _) 
    ^ draw-game-over(state, _)
end

fun draw-egg(egg-state :: Egg, current-img :: Image) -> Image:
  doc: " Draws the egg "

  egg-image = circle(EGG-RADIUS, "solid", EGG-COLOR)
  I.place-image(egg-image, egg-state.x, egg-state.y, current-img)
end

### TICKS ###

fun tick-handler(state :: State) -> State:
  cases (GameStatus) state.game-status:
    | ongoing =>
      state
        ^ update-platforms-x(_)
        ^ update-egg-ongoing(_)

    | transitioning =>
      state
        ^ update-platforms-y(_)

    | game-over => state
  end
end

#### EGGS ####

fun update-egg-ongoing(state :: State) -> State:
  doc: ```
       Game logic for the egg while game is ongoing
       ```
  current-plat = current-platform-data(state)
  next-plat = next-platform-data(state)

  if state.current-platform == top-lvl: # when egg at top, transition
    state.{game-status: transitioning}

  else if state.egg.is-airborne and egg-landed(state): # when egg lands
    landed-egg = state.egg.{
      y: (next-plat.y - (PLATFORM-HEIGHT / 2)) - EGG-RADIUS,
      dx: next-plat.dx,
      dy: 0,
      is-airborne: false,
      ay: 0,
    }
    state.{
      egg: landed-egg,
      current-platform: next-platform(state.current-platform),
      score : state.score + 1
    }
    
  else if state.egg.is-airborne and ((state.egg.y - EGG-RADIUS) > SCREEN-HEIGHT): # when egg dies
    
    new-life = state.lives - 1
    
    if (new-life == 0):
      state.{
        game-status: game-over,
        lives: 0
      }
    else:
      return-egg = state.egg.{
        x: current-plat.x,
        y: (current-plat.y - (PLATFORM-HEIGHT / 2)) - EGG-RADIUS,
        dx: current-plat.dx,
        dy: 0,
        is-airborne: false,
        ay: 0
      }
      state.{
        egg: return-egg,
        lives: new-life
      }
    end

  else if state.egg.is-airborne: # and not landed yet
    falling-egg = state.egg.{
      y: state.egg.y + state.egg.dy,
      dy: state.egg.dy + state.egg.ay
    }
    state.{egg: falling-egg}

  else: # when egg on platform
    fixed-egg = state.egg.{
      x: state.egg.x + state.egg.dx,
      dx: current-plat.dx
    }
    state.{egg: fixed-egg}

  end
end

fun egg-landed(state :: State) -> Boolean:
  doc: " Checks if egg intersects with a platform "

  fun egg-touches-platform-top(s :: State, next) -> Boolean:
    doc: " Top OF platform. Checks a range rather than if egg bottom point exactly matches platform top."

    egg-bottom = state.egg.y + EGG-RADIUS
    platform-top = next.y - (PLATFORM-HEIGHT / 2)
    platform-center = next.y
    (platform-top <= egg-bottom) and (egg-bottom <= platform-center)
  end

  next-plat = next-platform-data(state)

  egg-falling = state.egg.dy > 0

  egg-bounded-left-inclusive = (next-plat.x - (PLATFORM-WIDTH / 2)) <= state.egg.x
  egg-bounded-right-inclusive = state.egg.x <= (next-plat.x + (PLATFORM-WIDTH / 2))
  egg-within-platform = egg-bounded-left-inclusive and egg-bounded-right-inclusive

  egg-falling and egg-within-platform and egg-touches-platform-top(state, next-plat)
end

#### PLATFORMS ####

fun current-platform-data(state :: State) -> Platform:
  cases (PlatformLevel) state.current-platform:
    | top-lvl => state.top-platform
    | middle-lvl => state.middle-platform
    | bottom-lvl => state.bottom-platform
  end
end

fun next-platform(current :: PlatformLevel) -> PlatformLevel:
  cases (PlatformLevel) current:
    | top-lvl => bottom-lvl
    | middle-lvl => top-lvl
    | bottom-lvl => middle-lvl
  end
end

fun next-platform-data(state :: State) -> Platform:
  cases (PlatformLevel) state.current-platform:
    | top-lvl => state.other-platforms.get(0)
    | middle-lvl => state.top-platform
    | bottom-lvl => state.middle-platform
  end
end

fun generate-platforms(initial-y) -> Platform:
  doc: " Creates random platform values "

  fun generate-random-x-positon(num):
    if ((num + PLATFORM-WIDTH) > SCREEN-WIDTH) or ((num - PLATFORM-WIDTH) < 0): # Edge case where platform is partially off screen
      generate-random-x-positon(num-random(SCREEN-WIDTH))
    else:
      num
    end
  end

  fun generate-random-dx(num):
    if num == 0: # Edge case where platform does not move
      generate-random-dx(num-random(MAX-PLATFORM-SPEED))
    else:
      num
    end
  end
  {
    x: generate-random-x-positon(num-random(SCREEN-WIDTH)),
    y: initial-y, 
    dx: generate-random-dx(num-random(MAX-PLATFORM-SPEED)), 
    dy: TRANSITION-DY
  }
  # {x: SCREEN-WIDTH / 2, y: initial-y, dx: 0, dy: TRANSITION-DY} # Stationary platforms for testing
end



fun get-new-platforms(state):
  doc: " Used for grabbing the elements on other-platforms list "

  {state.other-platforms.get(0);
    state.other-platforms.get(1)}
end



fun make-pair-platforms():
  doc: " Creates a new pair of top and middle platforms respectively for transitioning. "

  [list: generate-platforms(1), generate-platforms(-124)]
end



fun check-platform-side-collision(platform :: Platform):
  doc: " Checks if platform hits the side walls. If so, negate dx. "

  if (platform.x + (PLATFORM-WIDTH / 2)) > SCREEN-WIDTH:
    platform.{dx: platform.dx * -1}

  else if (platform.x - (PLATFORM-WIDTH / 2)) < 0:
    platform.{dx: platform.dx * -1}

  else:
    platform.{dx: platform.dx * 1}

  end
end



fun update-platforms-x(state :: State):
  doc: " Used for horizontal movement. If platform hits wall, it must move away "

  top = check-platform-side-collision(state.top-platform)
  new-top = top.{x: top.x + top.dx}


  middle = check-platform-side-collision(state.middle-platform)
  new-middle = middle.{x: middle.x + middle.dx}


  bottom = check-platform-side-collision(state.bottom-platform)
  new-bottom = bottom.{x: bottom.x + bottom.dx}

  state.{top-platform: new-top, middle-platform: new-middle, bottom-platform: new-bottom}
end



fun update-platforms-y(state :: State):
  doc: " Used for transitioning. Moves down all platforms and egg by TRANSITION-DY "
  top = state.top-platform
  new-top = top.{y: top.y + top.dy}


  middle = state.middle-platform
  new-middle = middle.{y: middle.y + middle.dy}


  bottom = state.bottom-platform
  new-bottom = bottom.{y: bottom.y + bottom.dy}

  transitioning-egg = state.egg.{y: state.egg.y + TRANSITION-DY}

  new-vals = get-new-platforms(state)
  {m; t} = new-vals

  pre-plat-m = state.{pre-platform-1: m}.pre-platform-1
  pre-plat-t = state.{pre-platform-2: t}.pre-platform-2

  # STOP TRANSITIONING -> ONGOING
  if new-top.y == 375: # When top reaches bottom position, return to game state.
    state.{
      game-status : ongoing, 
      top-platform: pre-plat-t, 
      middle-platform: pre-plat-m, 
      bottom-platform: state.top-platform, 
      pre-platform-1: DEFAULT-HIDDEN-PLATFORM, # Resets hidden platforms when on game state
      pre-platform-2: DEFAULT-HIDDEN-PLATFORM, # Resets hidden platforms when on game state
      other-platforms: state.other-platforms.drop(2).append(make-pair-platforms()), # Deletes the 2 used platforms and generates new pair of platforms
      current-platform: bottom-lvl,
      egg: transitioning-egg,
    }


    # TRANSITIONING  
  else if (new-middle.y - 5) > SCREEN-HEIGHT: # If the original middle platform is outside the screen, change the value of middle-platform to the new onscreen top platform.
    state.{
      top-platform: new-top, 
      middle-platform: pre-plat-t, 
      bottom-platform: pre-plat-m, 
      other-platforms: 
        state.other-platforms.map(lam(platform): platform.{y: platform.y + platform.dy} end),
      egg: transitioning-egg,
    }

  else if (new-bottom.y - 5) > SCREEN-HEIGHT: # If the original bottom platform is outside the screen, change the value of bottom-platform to the new onscreen middle platform.
    state.{
      top-platform: new-top, 
      middle-platform: new-middle, 
      bottom-platform: pre-plat-m, 
      other-platforms: state.other-platforms.map(lam(platform): platform.{y: platform.y + platform.dy} end),
    egg: transitioning-egg,
    }

  else: # Updates the y coordinates of the offscreen platforms and draws them during transitioning.
    state.{
      top-platform: new-top, 
      middle-platform: new-middle, 
      bottom-platform: new-bottom, 
      other-platforms: state.other-platforms.map(lam(platform): platform.{y: platform.y + platform.dy} end), 
      pre-platform-1: pre-plat-m, 
      pre-platform-2: pre-plat-t,
      egg: transitioning-egg,
    }
  end
end

### KEYBOARD ###

fun key-handler(state :: State, key :: String) -> State:
  if key == ' ':
    cases (GameStatus) state.game-status:
      | ongoing => 
        if not(state.egg.is-airborne):
          jumped-egg = state.egg.{dx: 0, dy: EGG-JUMP-DY, is-airborne: true, ay: A-DUE-TO-G}
          state.{egg: jumped-egg}
        else: # Space does nothing when airborne
          state
        end
      | transitioning => state
      | game-over => 
        INITIAL-STATE = 
        {
          game-status : ongoing,
          egg: {x: 0, y: BOTTOM-PLATFORM-Y - 25, dx: 0, dy: 0, ay: 0, is-airborne: false},
          top-platform : generate-platforms(TOP-PLATFORM-Y),
          middle-platform : generate-platforms(MIDDLE-PLATFORM-Y),
          bottom-platform :  generate-platforms(BOTTOM-PLATFORM-Y),
          pre-platform-1 : DEFAULT-HIDDEN-PLATFORM, # OUTSIDE THE SCREEN PLATFORMS
          pre-platform-2 : DEFAULT-HIDDEN-PLATFORM, # OUTSIDE THE SCREEN PLATFORMS
          other-platforms : [list: generate-platforms(1), generate-platforms(-124)], # randomized initial values
            current-platform : bottom-lvl,
            score : 0,
            lives : DEFAULT-NUM-LIVES,
        }
        INITIAL-STATE.{
          egg: INITIAL-STATE.egg.{
          x: INITIAL-STATE.bottom-platform.x,
              dx: INITIAL-STATE.bottom-platform.dx,
            }
        }
    end
  else:
    state
  end
end

### MAIN ###

INITIAL-STATE = {
  game-status : ongoing,
  egg: {x: 0, y: BOTTOM-PLATFORM-Y - 25, dx: 0, dy: 0, ay: 0, is-airborne: false},
  top-platform : generate-platforms(TOP-PLATFORM-Y),
  middle-platform : generate-platforms(MIDDLE-PLATFORM-Y),
  bottom-platform :  generate-platforms(BOTTOM-PLATFORM-Y),
  pre-platform-1 : DEFAULT-HIDDEN-PLATFORM, # OUTSIDE THE SCREEN PLATFORMS
  pre-platform-2 : DEFAULT-HIDDEN-PLATFORM, # OUTSIDE THE SCREEN PLATFORMS
  other-platforms : [list: generate-platforms(1), generate-platforms(-124)], # randomized initial values
  current-platform : bottom-lvl,
  score : 0,
  lives : DEFAULT-NUM-LIVES,
}



world = reactor:
  title: 'CS 12 21.2 MP Demo',
  init: INITIAL-STATE.{
      egg: INITIAL-STATE.egg.{
          x: INITIAL-STATE.bottom-platform.x,
          dx: INITIAL-STATE.bottom-platform.dx,
        }
    },
  to-draw: draw-handler,
  seconds-per-tick: 1 / FPS,
  on-tick: tick-handler,
  on-key: key-handler,
end

R.interact(world)
