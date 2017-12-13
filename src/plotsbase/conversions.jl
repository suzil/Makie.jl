#heh, wonderful ctype :)
const Font = Vector{Ptr{FreeType.FT_FaceRec}}

"""
Any GLAbstraction.Camera
"""
function to_camera(scene, x::GLAbstraction.Camera)
    x
end
"""
Takes a camera symbol, one of :auto, :perspective, :orthographic, :pixel
"""
function to_camera(scene, x::Symbol)
    if x in (:auto, :perspective, :orthographic, :pixel)
        return x
    else
        error(":$x is not a supported camera symbol. Try one of :auto, :perspective, :orthographic, :pixel")
    end
end

nd_default(::Type{Vec{N, T}}) where {N, T} = one(T) # for scaling
nd_default(::Type{VT}) where VT <: VecLike{N, T} where {N, T} = zero(T) # 0 seems to be a good general default

function to_ndimensions(scene, ::Type{VT}, value::Number, default = 0) where VT <: VecLike{N, T} where {N, T}
    VT(ntuple(Val{N}) do i
        Float32(value)
    end)
end

function to_ndimensions(scene, ::Type{VT}, vec::VecLike{N2}, default = nd_default(VT)) where N2 where VT <: VecLike{N, T} where {N, T}
    VT(ntuple(Val{N}) do i
        val = i > N2 ? default : vec[i]
        Float32(val)
    end)
end

"""
to vector of vec3
"""
to_vec3s(scene, x) = to_vec3.(scene, x)

"""
to Vec3f0
"""
to_vec3(scene, x) = to_ndimensions(scene, Vec3f0, x)


"""
    to_float(scene, x)
Any Object convertible to Floatingpoint
"""
to_float(scene, x) = Float32(to_absolute(scene, x))


"""
2 Numbers for each dimension
"""
to_2floats(scene, x) = to_ndimensions(scene, NTuple{2, Float32}, to_absolute(scene, x))

"""
3 Numbers for each dimension
"""
to_3floats(scene, x) = to_ndimensions(scene, NTuple{3, Float32},  to_absolute(scene, x))


"""
    to_scale(scene, s)::Vec

Can be construced from a number 2d or 3d vec - will be converted to 3d vec
"""
to_scale(scene, x) = to_ndimensions(scene, Vec3f0, x)

"""
    to_offset(scene, s)::Point
Can be construced from a number 2d or 3d vec - will be converted to 3d point
"""
to_offset(scene, x) = to_ndimensions(scene, Point3f0, x)
to_offset(scene, x::VecLike{2}) = Point3f0(to_absolute(scene, x)..., 0)




"""
    to_image(scene, image) Array{Ptr{FreeType.FT_FaceRec},1}
All kinds of images
"""
to_image(scene, image) = image

"""
    to_bool(scene, bool)
To boolean
"""
to_bool(scene, bool) = Bool(bool)

"""
    to_bool(scene, tuple)
Accepts Tuple of Bool
"""
to_bool(scene, x::Tuple) = Bool.(x)


"""

    to_index_buffer(scene, x::GLBuffer{UInt32})
"""
to_index_buffer(scene, x::GLBuffer) = x

"""
`TOrSignal{Int}, AbstractVector{UnitRange{Int}}, TOrSignal{UnitRange{Int}}`
"""
to_index_buffer(scene, x::Union{TOrSignal{Int}, VecOrSignal{UnitRange{Int}}, TOrSignal{UnitRange{Int}}}) = x

"""
`AbstractVector{<:Integer}` assumend 1-based indexing
"""
function to_index_buffer(scene, x::AbstractVector{I}) where I <: Integer
    gpu_mem = GLBuffer(Cuint.(to_value(x) .- 1), buffertype = GL_ELEMENT_ARRAY_BUFFER)
    x = lift_node(to_node(x)) do x
        val = Cuint[i-1 for i = x]
        update!(gpu_mem, val)
     end
    gpu_mem
end

"""
`AbstractVector{<:Face{2}}` for linesegments
"""
function to_index_buffer(scene, x::AbstractVector{I}) where I <: Face{2}
    Face{2, GLIndex}.(x)
end

"""
`AbstractVector{UInt32}`, is assumed to be 0 based
"""
function to_index_buffer(scene, x::AbstractVector{UInt32})
    gpu_mem = GLBuffer(to_value(x), buffertype = GL_ELEMENT_ARRAY_BUFFER)
    lift_node(to_node(x)) do x
        update!(gpu_mem, x)
    end
    gpu_mem
end

to_index_buffer(scene, x) = error(
    "Not a valid index type: $(typeof(x)).
    Please choose from Int, Vector{UnitRange{Int}}, Vector{Int} or a signal of either of them"
)


"""
    to_positions(scene, positionlike)
`NTuple{2/3, AbstractArray{Float}}` for 2/3D points
"""
function to_positions(scene, x...)
    to_position.(scene, x...)
end


"""
`view(AbstractArray{Point}, idx)` for a subset of points. Can be shared (so you can plot subsets of the same data)!
"""
function to_positions(scene, x::SubArray)
    view(to_positions(scene, x.parent), x.indexes...)
end

"""
`AbstractArray{T}` where T needs to have `length` defined and must be convertible to a Point
"""
function to_positions(scene, x::AbstractArray)
    to_position.(scene, x)
end

function to_positions(scene, x::StaticVector)
    error("Please use an array of StaticVectors for positions. Found: $(typeof(x))")
end

function to_positions(scene, x::GeometryPrimitive)
    to_positions(scene, decompose(Point, x))
end

function to_positions(scene, x::SimpleRectangle)
    # TODO fix the order of decompose
    to_positions(scene, decompose(Point, x)[[1, 2, 4, 3, 1]])
end

function to_positions(scene, x)
    error("Not a valid position type: $(typeof(x)). Please read the documentation of [`to_positions`](@ref)")
end

to_position(scene, x::Point{N}) where N = Point{N, Float32}(x)
to_position(scene, x::Point{N, T}) where {N, T <: Unit} = Point{N, Float32}(to_absolute(scene, x))

"""
Converts a Vec like to a position (Point)
"""
function to_position(scene, x::VecLike{N}) where N
    to_position(scene, Point{N}(x))
end

"""
    match(value, tomatch, returnvalue)

returns `returnvalue` if `value` and `tomatch` are the same
"""
macro match(a, b, c)
    :($(esc(a)) == $(esc(b)) && return c)
end

function to_relative(x::Symbol)

    @match x :left (0rel, 0.5rel)
    @match x :right (1rel, 0.5rel)
    @match x :top (0.5rel, 1rel)
    @match x :inside (0.5rel, 0.5rel)

    @match x :topleft (0rel, 1rel)
    @match x :topright (1rel, 1rel)

    @match x :bottomleft (0rel, 0rel)
    @match x :bottomright (1rel, 0rel)

end
"""
    to_position(scene, x::Symbol)
Converts a Symbol to a relative position.
Applicable symbols:
    (:right, :left, :top, :bottom, :inside, :topright, :topleft, :bottomleft, :bottomright)
"""
function to_position(scene, x::Symbol)
    pos = to_relative(x)
    to_position(scene, pos)
end
function to_position(scene, x, y)
    to_position(scene, Point{2}(x, y))
end
function to_position(scene, x, y, z)
    to_position(scene, Point{3}(x, y, z))
end
function to_position(scene, x::AbstractArray)
    to_position(scene, Point{length(T)}(x))
end

"""
    to_array(scene, arraylike)
`AbstractArray`
"""
to_array(scene, x) = collect(x)

"""
    to_scalefunc(scene, x)
`Function`
"""
to_scalefunc(scene, x) = x # TODO implement it

"""
    to_text(scene, x)
All text
"""
to_text(scene, x) = x# TODO implement it

"""
    to_font(scene, x)
a string naming a font, e.g. helvetica
"""
function to_font(scene, x::Union{Symbol, String})
    str = string(x)
    if str == "default"
        return GLVisualize.defaultfont()
    end
    newface(format(match(Fontconfig.Pattern(string(x))), "%{file}"))
end
to_font(scene, x::Font) = x
function to_font(scene, x)
    error("Please use a string like \"Helvetica\" or a font loaded with FreeType!. Found: $x")
end


function to_textattribute(scene, x::NTuple{5, Any})
    TextAttributes(scene, x...)
end
function to_textattribute(scene, x::Tuple)
    to_textattribute.(scene, x)
end

"""
Text align, e.g. :
"""
to_textalign(b, x::Tuple{Symbol, Symbol}) = Vec2f0(alignment2num.(x))

to_string(scene, x::String) = x
to_string(scene, x) = string(x)


"""
    to_colornorm(scene, norm, intensity)
anything that can be converted to `Vec2f0` (e.g. `Tuple`, `Vector`)
"""
to_colornorm(scene, norm, intensity) = Vec2f0(norm)

"""
If colornorm is `nothing` will default to calculate the extrema from `intensity`
"""
function to_colornorm(scene, norm::Void, intensity)
    nan_extrema(intensity)
end

"""
`AbstractArray`
"""
to_intensity(scene, x::AbstractArray) = x # TODO implement

"""
    to_surface(scene, x::Range)
`Range`
"""
to_surface(scene, x::Range) = x
"""
    to_surface(scene, arraylike)
Anything that can be converted to Matrix/Vector of Float32
"""
to_surface(scene, x) = Float32.(x)


const Image = Matrix{T} where T <: Colorant

const _marker_map = Dict(
    :rect => '■',
    :star5 => '★',
    :diamond => '◆',
    :hexagon => '⬢',
    :cross => '✚',
    :xcross => '❌',
    :utriangle => '▲',
    :dtriangle => '▼',
    :ltriangle => '◀',
    :rtriangle => '▶',
    :pentagon => '⬟',
    :octagon => '⯄',
    :star4 => '✦',
    :star6 => '🟋',
    :star8 => '✷',
    :vline => '┃',
    :hline => '━',
    :+ => '+',
    :x => 'x',
    :circle => '●'
)


"""
    available_marker_symbols()
Displays all available marker symbols
"""
function available_marker_symbols()
    println("Marker Symbols:")
    for (k, v) in _marker_map
        println("    ", k, " => ", v)
    end
end


"""
    to_spritemarker(scene, x::Circle)
`GeometryTypes.Circle(Point2(...), radius)`
"""
to_spritemarker(scene, x::Circle) = x

"""
    to_spritemarker(scene, ::Type{Circle})
`Type{GeometryTypes.Circle}`
"""
to_spritemarker(scene, ::Type{Circle}) = Circle(Point2f0(0), 1f0)
"""
    to_spritemarker(scene, ::Type{Rectangle})
`Type{GeometryTypes.Rectangle}`
"""
to_spritemarker(scene, ::Type{Rectangle}) = HyperRectangle(Vec2f0(0), Vec2f0(1))
"""
    to_spritemarker(scene, marker::Char)
Any `Char`, including unicode
"""
to_spritemarker(scene, marker::Char) = marker

"""
Matrix of AbstractFloat will be interpreted as a distancefield (negative numbers outside shape, positive inside)
"""
to_spritemarker(scene, marker::Matrix{<: AbstractFloat}) = Float32.(marker)

"""
Any AbstractMatrix{<: Colorant} or other image type
"""
to_spritemarker(scene, marker::Image) = to_image(marker)

"""
A `Symbol` - Available options can be printed with `available_marker_symbols()`
"""
function to_spritemarker(scene, marker::Symbol)
    if haskey(_marker_map, marker)
        return to_spritemarker(scene, _marker_map[marker])
    else
        warn("Unsupported marker: $marker, using ● instead")
        return '●'
    end
end


to_spritemarker(scene, marker::AbstractVector{Char}) = marker

"""
Vector of anything that is accepted as a single marker will give each point it's own marker.
Note that it needs to be a uniform vector with the same element type!
"""
function to_spritemarker(scene, marker::AbstractVector)
    map(marker) do sym
        to_spritemarker(scene, sym)
    end
end


# function to_spritemarker(shape::Shape)
#     points = Point2f0[GeometryTypes.Vec{2, Float32}(p) for p in zip(shape.x, shape.y)]
#     bb = GeometryTypes.AABB(points)
#     mini, maxi = minimum(bb), maximum(bb)
#     w3 = maxi-mini
#     origin, width = Point2f0(mini[1], mini[2]), Point2f0(w3[1], w3[2])
#     map!(p -> ((p - origin) ./ width) - 0.5f0, points, points) # normalize and center
#     GeometryTypes.GLNormalMesh(points)
# end
# create a marker/shape type



"""
Any AbstractArray which elements can be converted to Vec4 (as a quaternion x, y, z, w)
"""
to_rotations(scene, x) = to_rotation.(scene, x)
to_rotations(scene, x::VecLike) = to_rotation(scene, x)

"""
    to_rotation(scene, vec4)
"""
to_rotation(scene, s::VecLike{4}) = Vec4f0(s)
"""
    to_rotation(scene, quaternion)
"""
to_rotation(scene, s::Quaternion) = Vec4f0(s.v1, s.v2, s.v3, s.s)

"""
    to_rotation(scene, tuple_float)
"""
to_rotation(scene, s::Tuple{<: VecLike, <: AbstractFloat}) = qrotation(to_ndimensions(scene, Vec3f0, s[1], 0f0), s[2])
"""
    to_rotations(scene, x)
`Billboard()` for a rotation that will always face the camera
"""
to_rotation(scene, x::Billboard) = x


to_nfloats(n::Type{Val{N}}, x::Number) where N = ntuple(i-> x, n)
function to_nfloats(n::Type{Val{N1}}, x::VecLike{N2, T}) where {N1, N2, T}
    ntuple(i-> i <= N2 ? x[i] : T(0), n)
end

"""
    to_markersize2d(scene, x)
Anything that can be converted to `Vec2f0` for x, y scale
"""
function to_markersize2d(scene, x::Union{VecLike, Number})
    a = to_absolute(scene, Vec(to_nfloats(Val{2}, x)))
    Vec2f0(a)
end
to_markersize2d(scene, x::AbstractArray) = to_markersize2d.(scene, x)


# TODO generically implement these to share implementation with to_position etc
"""
    to_markersize3d(scene, x)
Anything that can be converted to `Vec3f0` for x, y, z scale
"""
to_markersize3d(scene, x::Union{VecLike, Number}) = to_ndimensions(scene, Vec3f0, x)
to_markersize3d(scene, x::AbstractArray) = to_markersize3d.(scene, x)

"""
    to_linestyle(scene, x)
`Nothing` for no style
"""
to_linestyle(scene, x::Void) = x

"""
`AbstractVector{<:AbstractFloat}` for denoting sequences of fill/nofill. E.g.
[0.5, 0.8, 1.2] will result in 0.5 filled, 0.3 unfilled, 0.4 filled. 1.0 unit is one linewidth!
"""
to_linestyle(scene, A::AbstractVector) = A
"""
A `Symbol` equal to `:dash`, `:dot`, `:dashdot`, `:dashdotdot`
"""
function to_linestyle(scene, ls::Symbol)
    return if ls == :dash
        [0.0, 1.0, 2.0, 3.0, 4.0]
    elseif ls == :dot
        tick, gap = 1/2, 1/4
        [0.0, tick, tick+gap, 2tick+gap, 2tick+2gap]
    elseif ls == :dashdot
        dtick, dgap = 1.0, 1.0
        ptick, pgap = 1/2, 1/4
        [0.0, dtick, dtick+dgap, dtick+dgap+ptick, dtick+dgap+ptick+pgap]
    elseif ls == :dashdotdot
        dtick, dgap = 1.0, 1.0
        ptick, pgap = 1/2, 1/4
        [0.0, dtick, dtick+dgap, dtick+dgap+ptick, dtick+dgap+ptick+pgap, dtick+dgap+ptick+pgap+ptick,  dtick+dgap+ptick+pgap+ptick+pgap]
    else
        error("Unkown line style: $linestyle. Available: :dash, :dot, :dashdot, :dashdotdot or a sequence of numbers enumerating the next transparent/opaque region")
    end
end

"""
    to_normals(scene, x)
Vector{Normal{3}}
"""
to_normals(scene, x) = x

"""
    to_faces(scene, x)
Any array of NTuple/GeometryTypes.Face
"""
function to_faces(scene, x::AbstractVector{NTuple{N, TI}}) where {N, TI <: Integer}
    to_faces(reinterpret(Face{N, TI}, x))
end

function to_faces(scene, faces::AbstractVector{<: Face})
    decompose(GLTriangle, faces)
end
function to_faces(scene, faces::AbstractVector{GLTriangle})
    faces
end

function to_faces(scene, x::Void)
    x
end

function to_faces(scene, x::Vector{Int})
    if length(x) % 3 != 0
        error("Int indices need to represent triangles, therefore need to be a multiple of three. Found: $(length(x))")
    end
    reinterpret(GLTriangle, UInt32.(x .- 1))
end


"""
    to_mesh(scene, meshlike)
`AbstractMesh`
"""
function to_mesh(scene, mesh::AbstractMesh)
    mesh
end

function to_mesh(scene, geom::GeometryPrimitive)
    GLNormalMesh(geom)
end

function to_mesh(scene, verts, faces, colors, attribute_id::Void)
    GLPlainMesh(verts, faces)
end
function to_mesh(scene, verts, faces, colors::Colorant, attribute_id::Void)
    GLNormalMesh(vertices = verts, faces = faces)
end

function to_mesh(scene, verts, faces, colors::AbstractVector, attribute_id::Void)
    v, f, c = verts, faces, colors
    if length(c) != length(v)
        error("You need one color per vertex. Found: $(length(v)) vertices, and $(length(c)) colors")
    end
    GLNormalVertexcolorMesh(vertices = v, faces = f, color = c)
end
function to_mesh(verts, faces, colors::AbstractVector, attribute_id::AbstractVector)
    v, f, c, id = verts, faces, colors, attribute_id
    if length(id) != length(v)
        error("You need one attribute per vertex. Found: $(length(v)) vertices, and $(length(id)) attributes")
    end
    GLNormalAttributeMesh(
        vertices = v, faces = f,
        attributes = c, attribute_id = id
    )
end

"""
    to_attribut_id(scene, x)
Index into Mesh attributes, Vector{Integer}
"""
to_attribut_id(backend, x) = x



to_color(c) = to_color(current_backend[], c)

"""
    to_color(scene, x)
`Colors.Colorants`
"""
to_color(scene, c::Colorant) = RGBA{Float32}(c)
"""
A `Symbol` naming a color, e.g. `:black`
"""
to_color(scene, c::Symbol) = to_color(scene, string(c))
"""
A `String` naming a color, e.g. `:black` or html style `#rrggbb`
"""
to_color(scene, c::String) = parse(RGBA{Float32}, c)
to_color(scene, c::UniqueColorIter) = to_color(scene, next(c))

"""
A Tuple or Array with elements that `to_color` accepts.
If Array is a Matrix it will get interpreted as an Image
"""
to_color(scene, c::Union{Tuple, AbstractArray}) = to_color.(scene, c)


"""
Tuple{<: ColorLike, <: AbstractFloat} for a transparent color
"""
to_color(scene, c::Tuple{T, F}) where {T, F <: Number} = RGBAf0(Colors.color(to_color(scene, c[1])), c[2])


const colorbrewer_names = Symbol[
    # All sequential color schemes can have between 3 and 9 colors. The available sequential color schemes are:
    :Blues,
    :Oranges,
    :Greens,
    :Reds,
    :Purples,
    :Greys,
    :OrRd,
    :GnBu,
    :PuBu,
    :PuRd,
    :BuPu,
    :BuGn,
    :YlGn,
    :RdPu,
    :YlOrBr,
    :YlGnBu,
    :YlOrRd,
    :PuBuGn,

    # All diverging color schemes can have between 3 and 11 colors. The available diverging color schemes are:
    :Spectral,
    :RdYlGn,
    :RdBu,
    :PiYG,
    :PRGn,
    :RdYlBu,
    :BrBG,
    :RdGy,
    :PuOr,

    #The number of colors a qualitative color scheme can have depends on the scheme. The available qualitative color schemes are:
    :Name,
    :Set1,
    :Set2,
    :Set3,
    :Dark2,
    :Accent,
    :Paired,
    :Pastel1,
    :Pastel2
]

"""
    available_gradients()

Prints all available gradient names
"""
function available_gradients()
    println("Gradient Symbol/Strings:")
    for name in colorbrewer_names
        println("    ", name)
    end
end

"""
    to_colormap(scene, x)
An `AbstractVector{T}` with any object that [`to_color`](@ref) accepts
"""
to_colormap(scene, cm::AbstractVector) = RGBAf0.(cm)

"""
Tuple(A, B) or Pair{A, B} with any object that [`to_color`](@ref) accepts
"""
function to_colormap(scene, cs::Union{Tuple, Pair})
    [to_color.(cs)...]
end

to_colormap(val) = to_colormap(current_backend[], val)

"""
A Symbol/String naming the gradient. For more on what names are available please see: `available_gradients()
"""
function to_colormap(scene, cs::Union{String, Symbol})
    cs_sym = Symbol(cs)
    if cs_sym in colorbrewer_names
        ColorBrewer.palette(string(cs_sym), 9)
    else
        #TODO integrate PlotUtils color gradients
        error("There is no color gradient named: $cs")
    end
end



"""
    to_spatial_order(scene, x)
"xy" or "yx"
"""
function to_spatial_order(scene, x)
    if !(x in ("yx", "xy"))
        error("Spatial order must be \"yx\" or \"xy\". Found: $x")
    end
    x
end

"""
:xy or :yx
"""
to_spatial_order(scene, x::Symbol) = to_spatial_order(scene, string(x))

"""
    to_interval(scene, x)
`Tuple{<: Number, <: Number}`
"""
function to_interval(scene, x)
    if isa(x, Tuple{<: Number, <: Number})
        return x
    else
        error("Not an accepted value for interval. Please have a look at the documentation for to_interval")
    end
end

"""
Pair{<: Number, <: Number} e.g. 2 => 100
"""
to_interval(scene, x::Pair{<: Number, <: Number}) = to_interval(scene, (x...,))

"""
`AbstractVector` will be interpreted as an interval from minimum to maximum
"""
to_interval(scene, x::AbstractVector) = to_interval(scene, (minimum(x), maximum(x)))



using GLVisualize: IsoValue, Absorption, MaximumIntensityProjection, AbsorptionRGBA, IndexedAbsorptionRGBA
export IsoValue, Absorption, MaximumIntensityProjection, AbsorptionRGBA, IndexedAbsorptionRGBA

"""
    to_volume_algorithm(scene, x)
Enum values: `IsoValue` `Absorption` `MaximumIntensityProjection` `AbsorptionRGBA` `IndexedAbsorptionRGBA`
"""
function to_volume_algorithm(scene, value)
    if isa(value, GLVisualize.RaymarchAlgorithm)
        return Int32(value)
    elseif isa(value, Int32) && value in 0:5
        return value
    else
        error("$value is not a valid volume algorithm. Please have a look at the documentation of `to_volume_algorithm`")
    end
end

"""
Symbol/String: iso, absorption, mip, absorptionrgba, indexedabsorption
"""
function to_volume_algorithm(scene, value::Union{Symbol, String})
    vals = Dict(
        :iso => IsoValue,
        :absorption => Absorption,
        :mip => MaximumIntensityProjection,
        :absorptionrgba => AbsorptionRGBA,
        :indexedabsorption => IndexedAbsorptionRGBA,
    )
    to_volume_algorithm(scene, get(vals, Symbol(value)) do
        error("$value not a valid volume algorithm. Needs to be in $(keys(vals))")
    end)
end

"""
Transforms scale, offset, rotation into one transformation model matrix
"""
function to_modelmatrix(b, scale, offset, rotation)
    q = Quaternion(rotation[4], rotation[1], rotation[2], rotation[3])
    transformationmatrix(offset, scale, q)
end
