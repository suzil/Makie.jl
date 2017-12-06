using GeometryTypes, Makie

include("noise.jl") #https://gist.github.com/SimonDanisch/89779b923d77a4ecdf61246cbe24611b#file-noise4-jl

# inspired by https://github.com/rougier/alien-life

resolution = (1000, 1000)
scene = Scene(resolution = resolution)

n = 60_000
radius = 400
wh = Point2f0(resolution)
length = 50
scale = 0.005f0

T = rand(n) .* 2*pi
R = sqrt.(rand(n))
P = Point2f0.(R.*cos.(T),  R.*sin.(T))

intensity = map(P) do p
    (1.001 - norm(p)) ^ 0.75
end
P .= P .* radius .+ (wh ./ 2f0,)
P0 = similar(P)

points = scatter(P, markersize = 5, color = (:black, 0.25))
lines(Circle(wh / 2f0, Float32(radius + 5)), color = :black, linewidth = 3)

headline = text(
    "Created with Makie.jl:",
    textsize = 40, color = :gray,
    color = [fill(:gray, 13); fill(:black, 9)],
    align = (:hcenter, :top),
    position = (0.5rel, 0.96rel)
)

# interactively play with attributes:
julia_logo = download("https://camo.githubusercontent.com/6d7260eaa159cfb838b45bf168ff77adecf8b198/68747470733a2f2f6a756c69616c616e672e6f72672f696d616765732f6c6f676f5f68697265732e706e67")
logo = FileIO.load(julia_logo)
julia_small = Images.restrict(Images.restrict(logo))
# remove border from resize
julia_small = julia_small[4:end-4, 4:end-4]

language = text(
    "With:",
    textsize = 20, color = :gray,
    position = (0.1rel, 0.05rel),
    align = (:left, :bottom),
)

img = image(
    julia_small, scale = 0.3,
    offset = (0.17rel, (0.028)rel)
)
inspiration = text(
    "Inspired by: Necessary Disorder & Nicolas P. Rougier",
    textsize = 20, color = :gray,
    position = (0.3rel, 0.05rel),
    align = (:left, :bottom),
)

function inner(p, intensity, scale, cos_t, sin_t, len)
    x, y = p[1], p[2]
    dx = noise4(scale * x, scale*y, cos_t, sin_t, 2)
    dx *= intensity*len
    dy = noise4(100f0 + scale*x, 200f0 + scale*y, cos_t, sin_t, 2)
    dy *= intensity*len
    Point2f0(x + dx, y + dy)
end
function nextpos(t)
    cos_t = Float32(1.5 * cos(2 * pi * t))
    sin_t = Float32(1.5 * sin(2 * pi * t))
    P0 .= inner.(P, intensity, scale, cos_t, sin_t, length)
end
io = VideoStream(scene, homedir() * "/Desktop/", "aliens2")
@async for t in linspace(0, 6, 1000)
    isopen(Makie.getscreen(scene)) || break
    P0 = nextpos(t)
    points[:positions] = P0
    recordframe!(io)
end
finish(io, "mp4") # or gif/webm

# Interactively play with attributes:
scale = 0.004
points[:color] = (:black, 0.25)
points[:strokewidth] = 0
points[:markersize] = 3

points[:color] = (:green, 0.1)
points[:markersize] = 10
points[:strokecolor] = (:black, 1.0)
points[:strokewidth] = 2
points[:strokecolor] = (:black, 0.6)

points[:markersize] = 5
points[:strokewidth] = 2
points[:strokecolor] = (:white, 0.6)
points[:color] = (:black, 0.4)
