using Reactive, GLWindow, GeometryTypes, GLVisualize, Colors, ColorBrewer, GLFW
import Base: setindex!, getindex, map, haskey, merge, merge!


"""
A Makie flavored Signal that can be used to link attributes
"""
struct Node{T, F}
    signal::Signal{T}
    # Conversion function for push! This is a bit a hack around the fact that you can't do things like
    # signal = map(conversion_func, Signal(RGB(0, 0, 0))); push!(signal, :red)
    # since the signal won't have the correct type. so we give the chance to pass a conversion function
    # at creation which will be called in push!
    convert::F
end

abstract type AbstractScene end

"""
A scene is a holder of attributes which are all of the type Node.
A scene can contain attributes, which are themselves scenes.
Nodes can be connected, since they're signals under the hood, which can be created from other nodes.
"""
struct Scene <: AbstractScene
    name::Symbol
    parent::Nullable{Scene}
    data::Dict{Symbol, Any}
    children::Vector{Scene}

    canvas
    transformation

    visual::RefValue{Any}
end

Base.start(x::Scene) = start(1)
Base.next(x::Scene, idx) = next(x.children, idx)
Base.done(x::Scene, idx) = done(x.children, idx)


attributes(scene::Scene) = copy(scene.data)



function Scene(parent = Nullable{Scene}(), name = :root)
    Scene(name, parent, Dict{Symbol, Any}(), Scene[], nothing, nothing, RefValue{Any}())
end


function Scene()
    signals = Dict(
        :scroll => (0.0, 0.0),
        :hasfocus => false,
        :area => IRec(0, 0, 0, 0),
        :dropped_files => String[],
        :unicode_input => Char[],
        :mouseposition => (0.0px, 0.0px),
        :open => false,
        :mouse_buttons => Set{Mouse.Button}(),
        :keyboard_buttons => Set{Keyboard.Button}(),
        :entered_window => false,
    )
    Scene(:root, Nullable{Scene}(), data)
end
# I/O without libuv, for use after STDOUT is finalized
raw_print(msg::AbstractString...) = ccall(:write, Cssize_t, (Cint, Cstring, Csize_t), 1, join(msg), length(join(msg)))
raw_println(msg::AbstractString...) = raw_print(msg..., "\n")


function push!(scene::Scene, childscene::Scene)
    push!(scene.children, childscene)
    scene
end

"""
Get's the backend native visual belonging to a scene. If
it isn't a visual, it will return nothing!
"""
native_visual(scene::Scene) = scene.visual[]

function Base.delete!(scene::Scene, name::Symbol)
    if haskey(scene, name)
        obj = scene[name]
        delete!(scene.data, name)
        if isa(obj, Scene)
            visual = native_visual(obj)
            if visual != nothing
                # Also delete the visual from renderlist
                delete!(rootscreen(scene), visual)
            end
        end
    end
end

parent(scene::Scene) = get(scene.parent)

function rootscene(scene::Scene)
    while !isnull(scene.parent)
        scene = parent(scene)
    end
    scene
end
function rootscreen(scene::Scene)
    getscreen(rootscene(scene))
end
function getcanvas(scene::Scene, err = true)
    while !isnull(scene.parent) && !haskey(scene, :canvas)
        scene = parent(scene)
    end
    get(scene, :canvas, nothing)
end

function hascanvas(scene)
    getcanvas(scene) != nothing
end

function getscreen(scene::Scene)
    to_value(getcanvas(scene)).screen
end

include("signals.jl")

scene_node(x::AbstractNode) = x
scene_node(x) = to_node(x, identity, Any)
# there is not much use in having scene being a node, besides that it's awkward to work with
scene_node(x::Scene) = x

function Base.show(io::IO, mime::MIME"text/plain", scene::Scene)
    println(io, "Scene $(scene.name):")
    show(io, mime, scene.data)
end

function Base.show(io::IO, scene::Scene)
    print(io, "Scene: $(scene.name)")
end

const global_scene = Scene[]

function GLAbstraction.center!(scene::Scene, border = 0.1)
    canvas = to_value(getcanvas(scene))
    screen = canvas.screen
    cam = canvas.camera
    proj = to_signal(cam[:projection])
    robjs = RenderObject[]
    for v in values(scene.data)
        isa(v, Scene) && native_visual(v) != nothing && v.name != :selection_rect || continue
        append!(robjs, extract_renderable(native_visual(v)))
    end
    bb = GLAbstraction.renderlist_boundingbox(robjs)
#    bb = AABB(minimum(bb) .- border, widths(bb) .+ 2border)
    reset!(canvas, bb, false)
    scene[:canvas] = Makie.Canvas(screen, canvas.camera)
    scene
end


export center!

function Plot()
    if isempty(global_scene)
        global_scene[] = Scene()
    end
    global_scene[]
end


include("themes.jl")

close_all_nodes(x::AbstractNode) = closenode!(x)
close_all_nodes(x) = x

function close_all_nodes(x::Scene)
    for (k, v) in x.data
        close_all_nodes(v)
    end
end

function Base.empty!(scene::Scene)
    close_all_nodes(scene)
    empty!(scene.data)
end



Base.get(f, x::Scene, key::Symbol, tail::Symbol...) = haskey(x, key, tail...) ? x[key, tail...] : f()
Base.get(x::Scene, key::Symbol, default) = haskey(x, key) ? x[key] : default

function setindex!(s::Scene, obj, key::Symbol, tail::Symbol...)
    s2 = get(s.data, key) do
        s2 = Scene(Dict{Symbol, Any}())
        s.data[key] = s2
        s2
    end
    s2[tail...] = obj
end

function Base.push!(s::Scene, obj::Scene)
    for (k, v) in obj.data
        s[k] = v
    end
end

function setindex!(s::Scene, obj, key::Symbol)
    if haskey(s, key) # if in dictionary, just push a new value to the signal
        node = s[key]
        if isa(node, Union{AbstractNode, Scene})
            push!(node, obj)
        else
            s.data[key] = obj
        end
    else
        s.data[key] = scene_node(obj)
    end
end

haskey(s::Scene, key::Symbol) = haskey(s.data, key)
function haskey(s::Scene, key::Symbol, tail::Symbol...)
    res = haskey(s, key)
    res || return false
    haskey(s[key], tail...)
end
getindex(s::Scene, key::NTuple{N, Symbol}) where N = getindex(s, key...)
getindex(s::Scene, key::Symbol) = s.data[key]
getindex(s::Scene, key::Symbol, tail::Symbol...) = s.data[key][tail...]


function merge(a::Scene, b::Scene)
    Scene(get(a.parent), merge(a.data, b.data))
end

function merge!(a::Scene, b::Scene)
    merge!(a.data, b.data)
    a
end

function unique_predictable_name(scene, name)
    i = 1
    unique = name
    while haskey(scene, unique)
        unique = Symbol("$name$i")
        i += 1
    end
    return unique
end

to_value(scene::Scene, s1::Symbol, srest::Symbol...) = to_value(scene[s1, srest...])


"""
Extract a default for `func` + `attribute`.
If the attribute is in kw_args that will be selected.]
Else will search in scene.theme.func for `attribute` and if not found there it will
search one level higher (scene.theme).
"""
function find_default(scene, kw_args, func, attribute)
    if haskey(kw_args, attribute)
        return kw_args[attribute]
    end
    if haskey(scene, attribute)
        return scene[attribute]
    end
    root = rootscene(scene) # theme is in root!
    if haskey(root, :theme)
        theme = root[:theme]
        if haskey(theme, Symbol(func), attribute)
            return theme[Symbol(func), attribute]
        elseif haskey(theme, attribute)
            return theme[attribute]
        else
            error("theme doesn't contain a default for $attribute. Please provide $attribute for $func")
        end
    else
        error("Scene doesn't contain a theme and therefore doesn't provide any defaults.
            Please provide attribute $attribute for $func")
    end
end
