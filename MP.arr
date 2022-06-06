#|

    [] Egg launching
    [] Platform placement and movement
    [] Platform landing
    [] Lives and game over
    [] Next stage panning

|#

use context essentials2021
include color
import reactors as R
import image as I


type Platform = {
  x :: Number,
  y :: Number,
  dx :: Number,
}

type State = {
  top-platform :: Platform,
  middle-platform :: Platform,
  bottom-platform :: Platform,
  #other-platforms :: List<Platform>,
}


FPS = 60

SCREEN-WIDTH = 300
SCREEN-HEIGHT = 500

PLATFORM-WIDTH = 60
PLATFORM-HEIGHT = 10
PLATFORM-COLOR = "red"

TOP-PLATFORM-Y = 100
MIDDLE-PLATFORM-Y = 250
BOTTOM-PLATFORM-Y = 400

MAX-PLATFORM-SPEED = 5


fun generate-random-x-positon(num):
  if ((num + PLATFORM-WIDTH) > SCREEN-WIDTH) or ((num - PLATFORM-WIDTH) < 0):
    generate-random-x-positon(num-random(SCREEN-WIDTH))
  else:
    num
  end
end

fun generate-random-dx(num):
  if num == 0:
    generate-random-dx(num-random(MAX-PLATFORM-SPEED))
  else:
    num
  end
end

fun generate-platforms(initial-y) -> Platform:
  {x: generate-random-x-positon(num-random(SCREEN-WIDTH)), y: initial-y, dx: generate-random-dx(num-random(MAX-PLATFORM-SPEED))}
end

INITIAL-STATE = {
  top-platform : generate-platforms(TOP-PLATFORM-Y),
  middle-platform : generate-platforms(MIDDLE-PLATFORM-Y),
  bottom-platform :  generate-platforms(BOTTOM-PLATFORM-Y),
  #|other-platforms : [list: 
      {x: SCREEN-WIDTH / 2, y: 100, dx: 0},
      {x: SCREEN-WIDTH / 2, y: 250, dx: 0},
      {x: SCREEN-WIDTH / 2, y: 400, dx: 0}
    ],|#
  
}


fun draw-platform(platform :: Platform, img :: Image) -> Image:
    platform-img = rectangle(PLATFORM-WIDTH, PLATFORM-HEIGHT, "solid", PLATFORM-COLOR)
    I.place-image(platform-img, platform.x, platform.y, img)
end

#|
   fun draw-platforms(state :: State, img :: Image) -> Image:
  # state.other-platforms.foldr(draw-platform(_, _), img)
  fun helper(lst :: List<Platform>, acc :: Image) -> Image:
    cases (List) lst:
      | empty => acc
      | link(f,r) => helper(r, draw-platform(f, acc))
    end
  end

  helper(state.other-platforms, img)
   end
|#

fun draw-handler(state :: State) -> Image:
  canvas = empty-color-scene(SCREEN-WIDTH, SCREEN-HEIGHT, "white")
  
  canvas
    ^ draw-platform(state.top-platform, _)
    ^ draw-platform(state.middle-platform, _)
    ^ draw-platform(state.bottom-platform, _)
end

fun check-platform-side-collision(platform :: Platform):
  if (platform.x + (PLATFORM-WIDTH / 2)) > SCREEN-WIDTH:
    platform.{dx: platform.dx * -1}
    
  else if (platform.x - (PLATFORM-WIDTH / 2)) < 0:
    platform.{dx: platform.dx * -1}
    
  else:
    platform.{dx: platform.dx * 1}
    
  end
end

fun tick-handler(state :: State) -> State:
  var-top-platform = check-platform-side-collision(state.top-platform)
  new-top-platform = var-top-platform.{x: var-top-platform.x + var-top-platform.dx}
  
  
  var-middle-platform = check-platform-side-collision(state.middle-platform)
  new-middle-platform = var-middle-platform.{x: var-middle-platform.x + var-middle-platform.dx}
  
  
  var-bottom-platform = check-platform-side-collision(state.bottom-platform)
  new-bottom-platform = var-bottom-platform.{x: var-bottom-platform.x + var-bottom-platform.dx}

  state.{top-platform: new-top-platform, middle-platform: new-middle-platform, bottom-platform: new-bottom-platform}
end

world = reactor:
  title: 'CS 12 21.2 MP Demo',
  init: INITIAL-STATE,
  to-draw: draw-handler,
  seconds-per-tick: 1 / FPS,
  on-tick: tick-handler,
    
end

R.interact(world)