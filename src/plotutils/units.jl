module Units

using ..Makie: VecLike, getscreen, to_value, to_world, rootscreen
#=
Absolute is the default, so any number not having a unit is treated as absolute
struct Absolute{T}
    number::T
end
=#
using AbstractNumbers, StaticArrays, GeometryTypes, GLFW, GLWindow, Reactive
import AbstractNumbers: numbertype, basetype, number
abstract type Unit{T} <: AbstractNumber{T} end

# We should always poison any calculation involving Units
Base.promote_rule(x::Type{<: Unit{T1}}, ::Type{T2}) where {T1 <: Number, T2 <: Number} = basetype(x){promot_type(T1, T2)}
Base.promote_rule(::Type{T1}, x::Type{<: Unit{T2}}) where {T1 <: Number, T2 <: Number} = basetype(x){promot_type(T1, T2)}
function Base.promote_rule(x::Type{<: Unit{T1}}, y::Type{<: Unit{T2}}) where {T1 <: Number, T2 <: Number}
    basetype(x){promote_type(T1, T2)}
end

# This is kind of wrong, since we need a scene for correct conversion.
# The correct version is to_absolute(scene, x::Unit)
number(x::Unit) = x.number

"""
Unit is relative to bounding frame.
E.g. if the area is IRect(0, 0, 100, 100)
Point(0.5rel, 0.5rel) == Point(50, 50)
"""
struct Relative{T <: Number} <: Unit{T}
    number::T
end
AbstractNumbers.basetype(::Type{<: Relative}) = Relative

"""
Unit is pixels on screen.
This one is a bit tricky, since it refers to a static attribute (pixels on screen don't change)
but since every visual is attached to a camera, the exact scale might change.
So in the end, this is just relative to some normed camera - the value on screen, depending on the camera,
will not actually sit on those pixels. Only camera that guarantees the correct mapping is the
`:pixel` camera type.
"""
struct Pixel{T} <: Unit{T}
    number::T
end
AbstractNumbers.basetype(::Type{<: Pixel}) = Pixel

"""
Millimeter on screen. This unit respects the dimension and pixel density of the screen
to represent millimeters on the screen. This is the must use unit for layouting,
that needs to look the same on all kind of screens. Similar as with the [`Pixel`](@ref) unit,
a camera can change the actually displayed dimensions of any object using the millimeter unit.
"""
struct Millimeter{T} <: Unit{T}
    number::T
end
AbstractNumbers.basetype(::Type{<: Millimeter}) = Millimeter

const rel = Relative(1)
const px = Pixel(1)
const mm = Millimeter(1)


"""
Default doesn't do anything
"""
function to_absolute(scene, x)
    x
end
#
#
# function to_absolute(scene, x::Millimeter{T}) where T
#     pixel = Float32(x * minimum(pixel_per_mm(scene)))px
#     to_absolute(scene, convert(Pixel, px)) - to_absolute(scene, 0px)
# end
# function to_absolute(scene, x::VecLike{2, <: Millimeter})
#     pixel = Float32.(x .* pixel_per_mm(scene)) .* px
#     to_absolute(scene, pixel) .- to_absolute(scene, Vec(0px, 0px))
# end
#
# function to_absolute(scene, x::Relative)
#     x * minimum(widths(scene))
# end

# similar_vec(::Type{V}, ::Type{ET}) where {V <: StaticVector, ET} = similar_type(V, ET)
# similar_vec(::Type{NTuple{N, T}}, ::Type{ET}) where {N, T, ET} = NTuple{N, ET}
#
# function to_absolute(scene, x::V) where V <: VecLike{N, T} where {N, T <: Relative{NT}} where NT
#     area = getscreen(scene).area.value
#     println(area)
#     (NT.(x) .* similar_vec(V, NT)(widths(area))) .- similar_vec(V, NT)(minimum(area))
# end

# function to_absolute(scene, x::VT) where VT <: VecLike{N, <: Pixel} where N
#     vec2 = Point2f0(ntuple(i-> i <= N ? x[i] : 0, Val{2}))
#     # TODO don't put cam into rootscreen
#     p = to_world(vec2, first(rootscreen(scene).cameras)[2])
#     Point(ntuple(i-> i <= 2 ? Float32(p[i]) : 0, Val{N}))
# end
#
# function to_absolute(scene, x::Pixel)
#     vec2 = Point2f0(Float32(x), 0)
#     p = to_world(vec2, first(rootscreen(scene).cameras)[2])
#     p[1]
# end


function get_scaled_dpi()
    monitor = GLFW.GetPrimaryMonitor()
    props = GLWindow.MonitorProperties(monitor)
    # it seems like small displays with high dpi make mm look quite big.
    # so lets scale it a bit. 518 is a bit arbitrary, but the scale of my
    # screen on which I test everything, hence it will make you see things as I do.
    # scaling = minimum(props.physicalsize) / 518
    min(props.dpi...) #* scaling # we do not start fiddling with differently scaled xy dpi's
end
function pixel_per_mm(scene)
    get_scaled_dpi() ./ 25.4
end


end

using .Units

using .Units: px, rel, mm, Millimeter, Pixel, Relative, to_absolute, Unit
export px, rel, mm, Millimeter, Pixel, Relative, to_absolute
