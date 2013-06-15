
module Graphics.Element (widthOf, heightOf, sizeOf,
                         width, height, size, opacity, color, tag, link,
                         image, fittedImage, croppedImage, tiledImage,
                         flow, up, down, left, right, inward, outward,
                         above, below, beside, layers,
                         container, absolute, relative,
                         middle, topLeft, topRight, bottomLeft, bottomRight,
                         midLeft, midRight, midTop, midBottom, middleAt,
                         topLeftAt, topRightAt, bottomLeftAt, bottomRightAt,
                         midLeftAt, midRightAt, midTopAt, midBottomAt,
                         spacer, newElement
                        ) where

import Native.Utils (guid, max, htmlHeight)
import JavaScript as JS
import List as List
import Color
import Maybe (Just, Nothing)

type Properties = {
  id      : Int,
  width   : Int,
  height  : Int,
  opacity : Float,
  color   : Maybe Color,
  href    : JSString,
  tag     : JSString,
  hover   : ()
 }

type Element = { props : Properties, element : ElementPrim }

-- Get the width of an Element
widthOf : Element -> Int
widthOf e = e.props.width

-- Get the height of an Element
heightOf : Element -> Int
heightOf e = e.props.height

-- Get the width and height of an Element
sizeOf : Element -> (Int,Int)
sizeOf e = (e.props.width, e.props.height)

-- Create an `Element` with a given width.
width : Int -> Element -> Element
width  nw e = let p = e.props
                  props = case e.element of
                            Image _ w h _ -> {p| height <- h/w*nw }
                            RawHtml html -> {p| height <- let (w,h) = htmlHeight nw html in h}
                            _ -> p
              in { element=e.element, props={props| width <- nw} }

-- Create an `Element` with a given height.
height : Int -> Element -> Element
height nh e = let p = e.props
                  props = case e.element of
                            Image _ w h _ -> {p| width <- w/h*nh }
                            _ -> p
              in { element=e.element, props={p| height  <- nh} }

-- Create an `Element` with a new width and height.
size : Int -> Int -> Element -> Element
size w h e = height h (width w e)

-- Create an `Element` with a given opacity. Opacity is a number between 0 and 1
-- where 0 means totally clear.
opacity : Float -> Element -> Element
opacity o e = let p = e.props in { element=e.element, props={p| opacity <- o} }

-- Create an `Element` with a given background color.
color : Color -> Element -> Element
color   c e = let p = e.props in
              { element=e.element, props={p| color <- Just c} }

-- Create an `Element` with a tag. This lets you link directly to it.
-- The element `(tag "all-about-badgers" thirdParagraph)` can be reached
-- with a link lik this: `/facts-about-animals.elm#all-about-badgers`
tag : String -> Element -> Element
tag  name e = let p = e.props in
              { element=e.element, props={p| tag   <- JS.fromString name} }

-- Create an `Element` that is a hyper-link.
link : String -> Element -> Element
link href e = let p = e.props in
              { element=e.element, props={p| href  <- JS.fromString href} }

emptyStr = JS.fromString ""
newElement w h e =
  { props = Properties (guid ()) w h 1 Nothing emptyStr emptyStr (), element = e }

data ElementPrim
  = Image ImageStyle Int Int JSString
  | Container Position Element
  | Flow Direction [Element]
  | Spacer
  | RawHtml JSString
  | Custom -- for custom Elements implemented in JS, see collage for example

data ImageStyle = Plain | Fitted | Cropped (Int,Int) | Tiled

-- Create an image given a width, height, and image source.
image : Int -> Int -> String -> Element
image w h src = newElement w h (Image Plain w h (JS.fromString src))

-- Create a fitted image given a width, height, and image source.
-- This will crop the picture to best fill the given dimensions.
fittedImage : Int -> Int -> String -> Element
fittedImage w h src = newElement w h (Image Fitted w h (JS.fromString src))

-- Create a cropped image. Take a rectangle out of the picture starting
-- at the given top left coordinate. If you have a 140-by-140 image,
-- the following will cut a 100-by-100 square out of the middle of it.
--
--         croppedImage (20,20) 100 100 "yogi.jpg"
croppedImage : (Int,Int) -> Int -> Int -> String -> Element
croppedImage pos w h src =
    newElement w h (Image (Cropped pos) w h (JS.fromString src))

tiledImage : Int -> Int -> String -> Element
tiledImage w h src =
    newElement w h (Image Tiled w h (JS.fromString src))

data Three = P | Z | N
data Pos = Absolute Int | Relative Float
type Position = { horizontal : Three, vertical : Three, x : Pos, y : Pos }

-- Put an element in a container. This lets you position the element really
-- easily, and there are tons of ways to set the `Position`.
-- To center `element` exactly in a 300-by-300 square you would say:
--
--         container 300 300 middle element
--
-- By setting the color of the container, you can create borders.
container : Int -> Int -> Position -> Element -> Element
container w h pos e = newElement w h (Container pos e)

-- Create an empty box. This is useful for getting your spacing right and
-- for making borders.
spacer : Int -> Int -> Element
spacer w h = newElement w h Spacer

data Direction = DUp | DDown | DLeft | DRight | DIn | DOut

-- Have a list of elements flow in a particular direction.
-- The `Direction` starts from the first element in the list.
--
--         flow right [a,b,c]
--
--           +---+---+---+
--           | a | b | c |
--           +---+---+---+
flow : Direction -> [Element] -> Element
flow dir es =
  let ws = List.map widthOf es
      hs = List.map heightOf es
      newFlow w h = newElement w h (Flow dir es)
  in 
  if es == [] then spacer 0 0 else
  case dir of
    DUp    -> newFlow (List.maximum ws) (List.sum hs)
    DDown  -> newFlow (List.maximum ws) (List.sum hs)
    DLeft  -> newFlow (List.sum ws) (List.maximum hs)
    DRight -> newFlow (List.sum ws) (List.maximum hs)
    DIn    -> newFlow (List.maximum ws) (List.maximum hs)
    DOut   -> newFlow (List.maximum ws) (List.maximum hs)

-- Stack elements vertically. To put `a` above `b` you would say:
--
--         a `above` b
above : Element -> Element -> Element
above hi lo =
    newElement (max (widthOf hi) (widthOf lo))
               (heightOf hi + heightOf lo)
               (Flow DDown [hi,lo])

-- Stack elements vertically. To put `a` below `b` you would say:
--
--         a `below` b
below : Element -> Element -> Element
below lo hi =
    newElement (max (widthOf hi) (widthOf lo))
               (heightOf hi + heightOf lo)
               (Flow DDown [hi,lo])

-- Put elements beside each other horizontally.
beside : Element -> Element -> Element
beside lft rht =
    newElement (widthOf lft + widthOf rht)
               (max (heightOf lft) (heightOf rht))
               (Flow right [lft,rht])

-- Layer elements on top of each other, starting from the bottom.
-- `(layers == flow outward)`
layers : [Element] -> Element
layers es = 
  let ws = List.map widthOf es
      hs = List.map heightOf es
  in  newElement (List.maximum ws) (List.maximum hs) (Flow DOut es)


-- Repetitive things --

absolute : Int -> Pos
absolute = Absolute
relative : Float -> Pos
relative = Relative

middle      : Position
middle      = { horizontal=Z, vertical=Z, x=Relative 0.5, y=Relative 0.5 }
topLeft     : Position
topLeft     = { horizontal=N, vertical=P, x=Absolute 0, y=Absolute 0 }
topRight    : Position
topRight    = { topLeft | horizontal <- P }
bottomLeft  : Position
bottomLeft  = { topLeft | vertical <- N }
bottomRight : Position
bottomRight = { bottomLeft | horizontal <- P }
midLeft     : Position
midLeft     = { middle  | horizontal <- N, x <- Absolute 0 }
midRight    : Position
midRight    = { midLeft | horizontal <- P }
midTop      : Position
midTop      = { middle  | vertical <- P, y <- Absolute 0 }
midBottom   : Position
midBottom   = { midTop  | vertical <- N }

middleAt          : Pos -> Pos -> Position
middleAt      x y = { horizontal = Z, vertical = Z, x = x, y = y }
topLeftAt         : Pos -> Pos -> Position
topLeftAt     x y = { horizontal = N, vertical = P, x = x, y = y }
topRightAt        : Pos -> Pos -> Position
topRightAt    x y = { horizontal = P, vertical = P, x = x, y = y }
bottomLeftAt      : Pos -> Pos -> Position
bottomLeftAt  x y = { horizontal = N, vertical = N, x = x, y = y }
bottomRightAt     : Pos -> Pos -> Position
bottomRightAt x y = { horizontal = P, vertical = N, x = x, y = y }
midLeftAt         : Pos -> Pos -> Position
midLeftAt     x y = { horizontal = N, vertical = Z, x = x, y = y }
midRightAt        : Pos -> Pos -> Position
midRightAt    x y = { horizontal = P, vertical = Z, x = x, y = y }
midTopAt          : Pos -> Pos -> Position
midTopAt      x y = { horizontal = Z, vertical = P, x = x, y = y }
midBottomAt       : Pos -> Pos -> Position
midBottomAt   x y = { horizontal = Z, vertical = N, x = x, y = y }

up : Direction
up = DUp

down : Direction
down = DDown

left : Direction
left = DLeft

right : Direction
right = DRight

inward : Direction
inward = DIn

outward : Direction
outward = DOut