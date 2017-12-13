#setup
using Makie, GLFW, GeometryTypes, Reactive, FileIO, ColorBrewer, Colors
using GLVisualize
using GLVisualize: loadasset, assetpath


#cell
scene = Scene(resolution = (500, 500))
scatter(linspace(1, 5, 100), rand(100), markersize = 2mm)
center!(scene)


#cell
img = loadasset("doge.png")
scene = Scene(resolution = (500, 500))
GLAbstraction.empty_shader_cache!()
# display(scene)
# show(scene)
# println(scene)
s2 = scatter(scene, s1[:positions], markersize = 6mm, marker = :circle, color = :white)
s1 = scatter(scene, rand(100) * 500, rand(100) * 500, markersize = 4mm, strokewidth = 1mm, strokecolor = s2[:color], marker = '🐱')
image(img)
center!(scene)
subscene = Scene(scene, Signal(SimpleRectangle(0, 0, 200, 200)), :test)
scatter(subscene, rand(20) * 200, rand(20) * 200, markersize = 4mm)
s2[:strokewidth] = 20
#cell
scene = Scene(resolution = (500, 500))
heatmap(rand(32, 32))
center!(scene)


#cell
scene = Scene(resolution = (500, 500))
s = scatter(Point2f0[(0, 0), (1, 0), (0, 1), (1, 1)], marker = [:diamond, :x, :circle, :cross])
s = scatter(Point2f0[(0, 0), (1, 0), (0, 1), (1, 1)], color = :red, markersize = 1mm)
# a = axis(linspace(0, 1, 4), linspace(0, 1, 4))
center!(scene);


#cell
scene = Scene(resolution = (500, 500))
pos = Point2f0[(0, 0), (1, 0), (0, 1), (1, 1)]
s = scatter(
    pos,
    color = :black, markersize = 6mm,
    strokewidth = 0.01,
    strokecolor = :green
)
# Damn this yield. But otherwise the canvas wont update and to_value(s, :markersize) will give an old value
# this needs a better design!
yield()
for p in pos
    radius = to_value(s, :markersize)[1] / 2f0
    println(radius)
    lines(Circle(p, radius), thickness = 2, color = :white)
end
s = scatter(pos, color = :red, markersize = 1mm)
# a = axis(linspace(0, 1, 4), linspace(0, 1, 4))
center!(scene);

text(
    "Hello my dear Tester", position = (0.5rel, 0.5rel),
    align = (:center,  :center),
    textsize = 10mm,
    font = "URW Chancery L"
)
