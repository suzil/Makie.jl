using Makie, GeometryTypes, GLAbstraction
using Makie: to_signal, add_pan, add_zoom, add_mousebuttons, add_mousedrag, selection_rect
using Base: RefValue

scene = Scene()

scat = scatter(rand(100) .* 500f0, rand(100) .* 500f0, markersize = 20)
addcam(scat, cam)
scat = scatter(rand(100) .* 500f0, rand(100) .* 500f0, markersize = 20)
addcam(scat, cam)
a = axis(linspace(0, 500, 5), linspace(0, 500, 5))
addcam(a, cam)



extract_renderable(a.visual)


function Canvas(scene, camera::T) where T
    screen = Makie.getscreen(scene)
    pxarea = HyperRectangle{2, Float64}(screen.area.value)
    px2mm = Float64(Makie.Units.pixel_per_mm(scene))
    mmsize = widths(pxarea) .* px2mm
    camarea = HyperRectangle{2, Float64}(to_value(camera, :area))
    Canvas{2, T}(pxarea, mmsize, camarea, camera)
end
