const Pixel64 = Pixel{Float64}
const Millimeter64 = Millimeter{Float64}
import .Units: to_absolute

struct Canvas{N, C}
    pixel::HyperRectangle{2, Float64} # pixel on screen
    # Actual physical size on monitor. In 3d this only roughly correlates to screen size
    # and can be changed by the user in any case for output!
    width_in_mm::Vec{N, Float64}
    # the rectangle the camera "can see"
    # kind of ill defined since it should be a cone, but since I don't really have
    # any code that can actually work with a cone, this will just end up as a wrong cube anyways
    # right now it just takes the size of the middle point between far and near
    cam_area::HyperRectangle{N, Float64}
    camera::C
end


to_mm(x) = convert(Millimeter, x)
to_px(x::Unit{T}) where T = convert(Pixel{T}, x)

function Canvas(scene)
    screen = Makie.getscreen(scene)
    pxarea = HyperRectangle{2, Float64}(screen.area.value)
    px2mm = Float64(Makie.Units.pixel_per_mm(scene))
    mmsize = widths(pxarea) .* px2mm
    Canvas{2, Void}(pxarea, mmsize, pxarea, nothing)
end
function Canvas(scene, camera::T) where T
    screen = Makie.getscreen(scene)
    pxarea = HyperRectangle{2, Float64}(screen.area.value)
    px2mm = Float64(Makie.Units.pixel_per_mm(scene))
    mmsize = widths(pxarea) .* px2mm
    camarea = HyperRectangle{2, Float64}(to_value(camera, :area))
    Canvas{2, T}(pxarea, mmsize, camarea, camera)
end


function pixel2mm(canvas::Canvas)
    canvas.width_in_mm ./ widths(canvas.pixel)
end

function to_absolute(canvas::Canvas{2, <: AbstractCamera}, x::Relative{T}) where T
    minimum(widths(canvas.cam_area)) .* T(x)
end
function to_absolute(canvas::Canvas{2, <: AbstractCamera}, x::Pixel{T}) where T
    T(x) .* minimum(Makie.wscale(canvas.pixel, canvas.cam_area))
end
function to_absolute(canvas::Canvas{2, <: AbstractCamera}, x::Millimeter{T}) where T
    to_absolute(canvas, to_px.(x)) .* minimum(pixel2mm(canvas))
end

function to_absolute(canvas::Canvas{2, <: AbstractCamera}, x::Vec{2, RT}) where {RT <: Relative{T}} where T
    Vec(widths(canvas.cam_area) .* T.(x))
end
function to_absolute(canvas::Canvas{2, <: AbstractCamera}, x::Vec{2, PT}) where {PT <: Pixel{T}} where T
    Vec(T.(x) .* Makie.wscale(canvas.pixel, canvas.cam_area))
end
function to_absolute(canvas::Canvas{2, <: AbstractCamera}, p::Vec{2, PT}) where {PT <: Millimeter{T}} where T
    ppx = to_absolute(canvas, to_px.(p)) .* pixel2mm(canvas)
    Vec(ppx)
end

function to_absolute(canvas::Canvas{2, <: AbstractCamera}, x::Point{2, RT}) where {RT <: Relative{T}} where T
    p = T.(x)
    cam_area = canvas.cam_area
    Point(widths(cam_area) .* p) .+ Point(minimum(cam_area))
end
function to_absolute(canvas::Canvas{2, <: AbstractCamera}, x::Point{2, PT}) where {PT <: Pixel{T}} where T
    cs = Makie.camspace(canvas.cam_area, canvas.pixel, T.(x))
    Point(cs)
end
function to_absolute(canvas::Canvas{2, <: AbstractCamera}, p::Point{2, PT}) where {PT <: Millimeter{T}} where T
    ppx = to_absolute(canvas, to_px.(p))
    ppxl = (ppx - to_absolute(canvas, Point(T(0.0)px, T(0.0)px))) .* pixel2mm(canvas)
    Point(ppx .+ ppxl)
end
# If we don't have a camera, we can't convert, so we just return the number!
to_absolute(scene::Canvas{N, Void}, x::Unit) where N = AbstractNumbers.number(x)
using AbstractNumbers
to_absolute(scene::Canvas{N, Void}, x::AbstractArray{<:Unit}) where N = AbstractNumbers.number.(x)
to_absolute(scene::Canvas{N, Void}, x::Number) where N = x

to_absolute(scene::Scene, x) = x
to_absolute(scene::Scene, x::Units.Unit) = to_absolute(to_value(scene, :canvas), x)
to_absolute(scene::Scene, x::AbstractArray{<:Units.Unit}) = to_absolute(to_value(scene, :canvas), x)
