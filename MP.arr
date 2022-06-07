#|

    [] Egg launching
    [/] Platform placement and movement
    [] Platform landing
    [] Lives and game over
    [P] Next stage panning

|#

use context essentials2021
import reactors as R
import image as I

### TYPES ###

data GameStatus:
  | ongoing
  | transitioning(ticks-left :: Number)          # IDK WHAT ticks-left do
  | game-over
end

type Platform = {
  x :: Number,
  y :: Number,
  dx :: Number,
  dy :: Number
}

type State = {
  game-status :: GameStatus,
  top-platform :: Platform,
  middle-platform :: Platform,
  bottom-platform :: Platform,
  pre-platform-1 :: Platform,
  pre-platform-2 :: Platform,
  other-platforms :: List<Platform>,
}



### CONSTANTS ###

FPS = 60

SCREEN-WIDTH = 300
SCREEN-HEIGHT = 500

PLATFORM-WIDTH = 60
PLATFORM-HEIGHT = 10
PLATFORM-COLOR = "red"

TOP-PLATFORM-Y = 125
MIDDLE-PLATFORM-Y = 250
BOTTOM-PLATFORM-Y = 375

DEFAULT-HIDDEN-PLATFORM = {x: 0, y: -5, dx: 0, dy:0}

PLATFORM-DY = 1
MAX-PLATFORM-SPEED = 5


### DRAW ###

fun draw-platform(platform :: Platform, img :: Image) -> Image:
  doc: " Draws a specific platform "
  
    platform-img = rectangle(PLATFORM-WIDTH, PLATFORM-HEIGHT, "solid", PLATFORM-COLOR)
    I.place-image(platform-img, platform.x, platform.y, img)
end

fun draw-handler(state :: State) -> Image:
  doc: " Draws all the elements used "
  
  canvas = empty-color-scene(SCREEN-WIDTH, SCREEN-HEIGHT, "white")
  canvas
    ^ draw-platform(state.top-platform, _)
    ^ draw-platform(state.middle-platform, _)
    ^ draw-platform(state.bottom-platform, _)
    ^ draw-platform(state.pre-platform-1, _)
    ^ draw-platform(state.pre-platform-2, _)
end




### TICKS ###

fun generate-platforms(initial-y) -> Platform:
  doc: " Creates random platform values "
  
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
  {x: generate-random-x-positon(num-random(SCREEN-WIDTH)), y: initial-y, dx: generate-random-dx(num-random(MAX-PLATFORM-SPEED)), dy: PLATFORM-DY}
end



fun get-new-platforms(state):
  doc: " Used for grabbing the elements on other-platforms list "
  
  {state.other-platforms.get(0); state.other-platforms.get(1)}
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
  doc: " Used for horizontal movement. If platform hits wall, must move away "
  
  top = check-platform-side-collision(state.top-platform)
  new-top = top.{x: top.x + top.dx}


  middle = check-platform-side-collision(state.middle-platform)
  new-middle = middle.{x: middle.x + middle.dx}


  bottom = check-platform-side-collision(state.bottom-platform)
  new-bottom = bottom.{x: bottom.x + bottom.dx}

  state.{top-platform: new-top, middle-platform: new-middle, bottom-platform: new-bottom}
end

fun update-platforms-y(state :: State):
  doc: " Used for transitioning. Moves down all platforms by 1 "
  top = state.top-platform
  new-top = top.{y: top.y + top.dy}


  middle = state.middle-platform
  new-middle = middle.{y: middle.y + middle.dy}


  bottom = state.bottom-platform
  new-bottom = bottom.{y: bottom.y + bottom.dy}
  
  new-vals = get-new-platforms(state)
  {m; t} = new-vals
  
  pre-plat-m = state.{pre-platform-1: m}.pre-platform-1
  pre-plat-t = state.{pre-platform-2: t}.pre-platform-2
  
  # STOP TRANSITIONING -> ONGOING
  if new-top.y == 375:
    state.{game-status : ongoing, top-platform: pre-plat-t, middle-platform: pre-plat-m, bottom-platform: state.top-platform, pre-platform-1: DEFAULT-HIDDEN-PLATFORM, pre-platform-2: DEFAULT-HIDDEN-PLATFORM, other-platforms: state.other-platforms.drop(2).append(make-pair-platforms()),}
    
    
  # TRANSITIONING  
  else if (new-middle.y - 5) > SCREEN-HEIGHT:
    state.{top-platform: new-top, middle-platform: pre-plat-t, bottom-platform: pre-plat-m, other-platforms: state.other-platforms.map(lam(platform): platform.{y: platform.y + platform.dy} end)}
    
  else if (new-bottom.y - 5) > SCREEN-HEIGHT:
    state.{top-platform: new-top, middle-platform: new-middle, bottom-platform: pre-plat-m, other-platforms: state.other-platforms.map(lam(platform): platform.{y: platform.y + platform.dy} end)}
    
  else:
    state.{top-platform: new-top, middle-platform: new-middle, bottom-platform: new-bottom, other-platforms: state.other-platforms.map(lam(platform): platform.{y: platform.y + platform.dy} end), pre-platform-1: pre-plat-m, pre-platform-2: pre-plat-t}
  end
end



fun tick-handler(state :: State) -> State:
  cases (GameStatus) state.game-status:
    | ongoing =>
      state
        ^ update-platforms-x(_)
      
    | transitioning(ticks-left)=>
      state
        ^ update-platforms-y(_)

        
    | game-over => state
  end
end



### MAIN ###

INITIAL-STATE = {
  game-status : transitioning(1),
  top-platform : generate-platforms(TOP-PLATFORM-Y),
  middle-platform : generate-platforms(MIDDLE-PLATFORM-Y),
  bottom-platform :  generate-platforms(BOTTOM-PLATFORM-Y),
  pre-platform-1 : DEFAULT-HIDDEN-PLATFORM, # OUTSIDE THE SCREEN PLATFORMS
  pre-platform-2 : DEFAULT-HIDDEN-PLATFORM, # OUTSIDE THE SCREEN PLATFORMS
  other-platforms : [list: generate-platforms(1), generate-platforms(-124)],
}


world = reactor:
  title: 'CS 12 21.2 MP Demo',
  init: INITIAL-STATE,
  to-draw: draw-handler,
  seconds-per-tick: 1 / FPS,
  on-tick: tick-handler,
    
end

R.interact(world)



#|fun draw-platforms(state :: State, img :: Image) -> Image:
  # state.other-platforms.foldr(draw-platform(_, _), img)
  fun helper(lst :: List<Platform>, acc :: Image, i :: Number) -> Image:
    #|cases (List) lst:
      | empty => acc
      | link(f,r) => helper(r, draw-platform(f, acc))
    end|#
    if i > 1:
      state.{top-platform: lst.get(i)}
    else:
      acc
    end
    
  end

  helper(state.other-platforms, img, 0)
   end|#