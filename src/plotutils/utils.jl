const VecLike{N, T} = Union{NTuple{N, T}, StaticVector{N, T}}

gpuvec(x) = GPUVector(GLBuffer(x))

function to_nd(x, n::Type{Val{N}}, default) where N
    ntuple(n) do i
        i <= length(x) && return x[i]
        default
    end
end


function to_world(point::T, cam) where T <: StaticVector
    x = to_world(
        point,
        inv(Reactive.value(cam.view)) * inv(Reactive.value(cam.projection)),
        T(widths(Reactive.value(cam.window_size)))
    )
    Point2f0(x[1], x[2])
end
function to_world(
        p::StaticVector{N, T},
        prj_view_inv::Mat4,
        cam_res::StaticVector
    ) where {N, T}
    VT = typeof(p)
    clip_space = ((VT(p) ./ VT(cam_res)) .* T(2)) .- T(1)
    pix_space = Vec{4, T}(
        clip_space[1],
        clip_space[2],
        T(0), GLAbstraction.w_component(p)
    )
    ws = prj_view_inv * pix_space
    ws ./ ws[4]
end

function qrotation(axis::StaticVector{N, T}, theta) where {N, T <: Real}
    if length(axis) != 3
        error("Must be a 3-vector")
    end
    u = normalize(axis)
    thetaT = convert(eltype(u), theta)
    s = sin(thetaT / T(2))
    Vec4f0(s * u[1], s * u[2], s * u[3], cos(thetaT / T(2)))
end

qabs(q) = sqrt(dot(q, q))

function qnormalize(q)
    q ./ qabs(q)
end

function qmul(quat::StaticVector{4}, vec::StaticVector{2})
    x3 = qmul(quat, Vec(vec[1], vec[2], 0))
    StaticArrays.similar_type(vec, StaticArrays.Size(2,))(x3[1], x3[2])
end
function qmul(quat::StaticVector{4}, vec::StaticVector{3})
    num = quat[1] * 2f0;
    num2 = quat[2] * 2f0;
    num3 = quat[3] * 2f0;
    num4 = quat[1] * num;
    num5 = quat[2] * num2;
    num6 = quat[3] * num3;
    num7 = quat[1] * num2;
    num8 = quat[1] * num3;
    num9 = quat[2] * num3;
    num10 = quat[4] * num;
    num11 = quat[4] * num2;
    num12 = quat[4] * num3;
    return Point3f0(
        (1f0 - (num5 + num6)) * vec[1] + (num7 - num12) * vec[2] + (num8 + num11) * vec[3],
        (num7 + num12) * vec[1] + (1f0 - (num4 + num6)) * vec[2] + (num9 - num10) * vec[3],
        (num8 - num11) * vec[1] + (num9 + num10) * vec[2] + (1f0 - (num4 + num5)) * vec[3]
    )
end
qconj(q) = Vec4f0(-q[1], -q[2], -q[3], q[4])

function qmul(q::StaticVector{4}, w::StaticVector{4})
    qq = Vec4f0(
        q[4] * w[4] - q[1] * w[1] - q[2] * w[2] - q[3] * w[3],
        q[4] * w[1] + q[1] * w[4] + q[2] * w[3] - q[3] * w[2],
        q[4] * w[2] - q[1] * w[3] + q[2] * w[4] + q[3] * w[1],
        q[4] * w[3] + q[1] * w[2] - q[2] * w[1] + q[3] * w[4],
    )
    qnormalize(qq)
end


is_unitrange(x) = (false, 0:0)
is_unitrange(x::Range) = (true, x)
function is_unitrange(x::AbstractVector)
    length(x) < 2 && return false, 0:0
    diff = x[2] - x[1]
    length(x) < 3 && return true, x[1]:x[2]
    last = x[3]
    for elem in drop(x, 3)
        diff2 = elem - last
        diff2 != diff && return false, 0:0
    end
    return true, range(first(x), diff, length(x))
end

function ngrid(x::AbstractVector, y::AbstractVector)
    xgrid = [Float32(x[i]) for i = 1:length(x), j = 1:length(y)]
    ygrid = [Float32(y[j]) for i = 1:length(x), j = 1:length(y)]
    xgrid, ygrid
end

function nan_extrema(array)
    mini, maxi = (Inf, -Inf)
    for elem in array
        isnan(elem) && continue
        mini = min(mini, elem)
        maxi = max(maxi, elem)
    end
    Vec2f0(mini, maxi)
end

# some type alias
const RGBAf0 = RGBA{Float32}

"""
A simple iterator that returns a new, unique color when `next(::UniqueColorIter)` is called.
"""
mutable struct UniqueColorIter{T}
    colors::T
    state::Int
end

UniqueColorIter(x::Union{Symbol, String}) = UniqueColorIter(to_colormap(x), 1)

function Base.getindex(iter::UniqueColorIter, idx::Int)
    # TODO make out of bounds more graceful? But hooow
    iter.colors[mod1(idx, length(iter.colors))]
end

Base.start(iter::UniqueColorIter) = (iter.state = 1; (iter, iter))

function Base.next(iter::UniqueColorIter)
    result = iter[iter.state]
    iter.state += 1
    result
end
# make the base interface happy
Base.next(iter::UniqueColorIter, iter2) = (next(iter), iter2)


"""
Billboard attribute to always have a primitive face the camera.
Can be used for rotation.
"""
immutable Billboard end


"""
2D Integer Rectangle
"""
function IRect(rect::SimpleRectangle)
    IRect(rect.x, rect.y, rect.w, rect.h)
end
function IRect(x, y, w, h)
    SimpleRectangle{Int}(round(Int, x), round(Int, y), round(Int, w), round(Int, h))
end
function IRect(xy::StaticVector, w, h)
    IRect(xy[1], xy[2], w, h)
end
function IRect(x, y, wh::StaticVector)
    IRect(x, y, wh[1], wh[2])
end
function IRect(xy::StaticVector, wh::StaticVector)
    IRect(xy[1], xy[2], wh[1], wh[2])
end

"""
2D Floatingpoint Rectangle
"""
function FRect(r::SimpleRectangle)
    SimpleRectangle{Float32}(r.x, r.y, r.w, r.h)
end
function FRect(x, y, w, h)
    SimpleRectangle{Float32}(x, y, w, h)
end

function FRect(xy::StaticVector, w, h)
    SimpleRectangle{Float32}(xy[1], xy[2], w, h)
end
function FRect(x, y, wh::StaticVector)
    SimpleRectangle{Float32}(x, y, wh[1], wh[2])
end
function FRect(xy::StaticVector, wh::StaticVector)
    SimpleRectangle{Float32}(xy[1], xy[2], wh[1], wh[2])
end
function FRect(prim::GeometryPrimitive{2})
    FRect(minimum(prim), widths(prim))
end
