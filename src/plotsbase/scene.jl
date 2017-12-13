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

"""
A scene is a holder of attributes which are all of the type Node.
A scene can contain attributes, which are themselves scenes.
Nodes can be connected, since they're signals under the hood, which can be created from other nodes.
"""
struct Scene{Backend}
    name::Symbol
    parent::Nullable{Scene}
    data::Dict{Symbol, Any}
    visual::RefValue{Any}
end

Base.start(x::Scene) = start(x.data)
Base.next(x::Scene, idx) = next(x.data, idx)
Base.done(x::Scene, idx) = done(x.data, idx)


attributes(scene::Scene) = copy(scene.data)


const current_backend = Ref(:makie)

function Scene(args...)
    Scene{current_backend[]}(args...)
end

"""
Creates a child scene containing a new window!
"""
function Scene(parent::Scene{Backend}, area, name = :scene, data = Dict{Symbol, Any}(); screen_kw_args...) where Backend
    screen = getscreen(parent)
    newscreen = Screen(screen; area = to_signal(area), screen_kw_args...)
    data[:canvas] = to_node(Makie.Canvas(newscreen), identity, Any)
    Scene{Backend}(name, parent, data, RefValue{Any}(nothing))
end

function Scene(parent::Scene{Backend}, scene::Scene, name = :scene) where Backend
    Scene{Backend}(name, Nullable(parent), scene.data, RefValue{Any}(nothing))
end

function Scene(parent::Scene{Backend}, scene::Dict, name = :scene) where Backend
    data = Dict{Symbol, Any}()
    for (k, v) in scene
        data[Symbol(k)] = scene_node(v)
    end
    Scene{Backend}(name, Nullable(parent), data, RefValue{Any}(nothing))
end
function Scene(parent::Scene{Backend}, name::Symbol = :scene; attributes...) where Backend
    Scene(parent, Dict{Symbol, Any}(attributes), name)
end


function (::Type{Scene{Backend}})(data::Dict, name = :scene) where Backend
    Scene{Backend}(name, Nullable{Scene{Backend}}(), data, RefValue{Any}(nothing))
end

function (::Type{Scene{Backend}})(pair1::Pair, tail::Pair...) where Backend
    args = [pair1, tail...]
    Scene(Dict(map(x-> x[1] => scene_node(x[2]), args)))
end

# I/O without libuv, for use after STDOUT is finalized
raw_print(msg::AbstractString...) =
    ccall(:write, Cssize_t, (Cint, Cstring, Csize_t), 1, join(msg), length(join(msg)))
raw_println(msg::AbstractString...) = raw_print(msg..., "\n")


"""
Inserts `childscene` into the scene graph of `scene`. This will display the
`childscene` in `scene`, when it is visible.
`show!` will get called by default for any plotting command, and can be disabled
and manually added via `show` by doing e.g.
    ```
    scene = Scene()
    scatplot = scatter(rand(10), rand(10), show = false)
    view!(scene, scatplot)
    ```
"""
function show!(scene::Scene{Backend}, childscene::Scene{Backend}) where Backend
    screen = getscreen(scene)
    viz = native_visual(childscene)
    viz == nothing && error("`childscene` does not contain any visual, so can't be added to `scene` with `show!`!")

    canvas = to_value(getcanvas(childscene, false))
    if canvas == nothing || canvas.camera == nothing
        initial_bb = data_boundingbox(childscene)
        canv = Makie.camera2d(scene, initial_bb)
        scene[:canvas] = canv
        canvas = scene[:canvas]
    end
    addcam(childscene, to_value(canvas).camera)

    push!.(screen, extract_renderable(viz))
    childscene
end

function insert_scene!(scene::Scene{Backend}, childscene) where Backend
    uname = unique_predictable_name(scene, childscene.name)
    scene.data[uname] = childscene
    to_value(get(childscene, :show, false)) && show!(scene, childscene)
    childscene
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
    !haskey(scene, :canvas) && err && throw("scene doesn't contain a canvas")
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
    for elem in robjs
        println(elem)
    end
    bb = GLAbstraction.renderlist_boundingbox(robjs)
#    bb = AABB(minimum(bb) .- border, widths(bb) .+ 2border)
    reset!(canvas, bb, false)
    scene[:canvas] = Makie.Canvas(screen, canvas.camera)
    scene
end


export center!

function get_global_scene()
    if isempty(global_scene)
        global_scene[] = Scene()
    end
    global_scene[]
end

render_frame(scene::Scene) = render_frame(rootscreen(scene))
function render_frame(screen::GLWindow.Screen)
    GLWindow.reactive_run_till_now()
    GLWindow.render_frame(screen)
    GLWindow.swapbuffers(screen)
end

function sort_zindex(rlist)
    for elem in rlist # tuple

    end
end

function render_loop(tsig, screen, framerate = 1/60)
    while isopen(screen)
        t = time()
        GLWindow.poll_glfw() # GLFW poll
        push!(tsig, t)
        if Base.n_avail(Reactive._messages) > 0
            render_frame(screen)
        end
        t = time() - t
        GLWindow.sleep_pessimistic(framerate - t)
    end
    GLWindow.destroy!(screen)
    return
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

const render_task = RefValue{Task}()

function block(scene::Scene)
    wait(render_task[])
end

function Scene(;
        theme = default_theme,
        resolution = nothing,
        position = nothing,
        color = :white,
        monitor = nothing
    )
    w = nothing
    scene = try
        tsig = to_node(0.0)
        if !isempty(global_scene)
            oldscene = global_scene[]
            oldscreen = getscreen(oldscene)
            nw = GLWindow.nativewindow(oldscreen)
            if position == nothing && isopen(nw)
                position = GLFW.GetWindowPos(nw)
            end
            if resolution == nothing && isopen(nw)
                resolution = GLFW.GetWindowSize(nw)
            end
            empty!(oldscreen)
            empty!(oldscreen.cameras)
            GLVisualize.empty_screens!()
            empty!(oldscene)
            empty!(global_scene)
            oldscreen.color = to_color(nothing, color)
            w = oldscreen
        end
        if w == nothing || !isopen(w)
            if resolution == nothing
                resolution = GLWindow.standard_screen_resolution()
            end
            w = Screen("Makie", resolution = resolution, color = to_color(nothing, color))
            GLWindow.add_complex_signals!(w)
        end
        if !isassigned(render_task) || istaskdone(render_task[])
            render_task[] = @async render_loop(tsig, w)
        end
        nw = GLWindow.nativewindow(w)
        if resolution == nothing
            resolution = GLWindow.standard_screen_resolution()
        end
        if position == nothing
            position = GLFW.GetWindowPos(nw)
        end
        GLFW.SetWindowPos(nw, position...)
        resize!(w, Int.(resolution)...)

        GLVisualize.add_screen(w)
        # These are derived signals, which we can't close and are sort of internal!
        filtered = filter(w.inputs) do k, v
            !(k in (
                :cursor_position,
                :window_size,
                :framebuffer_size
            ))
        end
        dict = map(filtered) do k_v
            k_v[1] => to_node(k_v[2])
        end
        push!(dict[:window_open], true)
        dict[:time] = tsig
        scene = Scene(dict)
        scene[:canvas] = to_node(Makie.Canvas(w), identity, Any)
        add_mousebuttons(scene)
        add_mousedrag(scene)
        scene[:keyboardbuttons] = lift_node(scene[:buttons_pressed]) do x
            map(Keyboard.Button, x)
        end
        push!(global_scene, scene)
        # Okay here is the thing.
        # We don't know at this point what kind of canvas we will have (2d/3d how big etc)
        # So we have a bit of a bootstrapping problem. We solve it by inserting
        # a canvas without camera as a node.
        # whenever we have our first plot and know if it's 2D/3D we push a new
        # canvas to this node. All attribute nodes are insert in this form:
        # lift_node(scene[:canvas], node) do scene, value
        #   convert_func(scene, value)
        # end
        # so whenever the canvas get's it's actually values, all conversion
        # functions can to the correct conversions to the correct units etc.
        # This solution is not perfect, since it will convert all attributes 2 times
        # so we should rethink this approach
        scene
    catch e
        if w != nothing
            GLWindow.destroy!(w) # make sure we don't have a broken window when stuff errors
        end
        rethrow(e)
    end
    theme(scene) # apply theme
    scene
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
    @ref(arg)

    ```julia
        @ref Variable = Value # Inserts Value under name Variable into Scene

        @ref Scene.Name1.Name2 # Syntactic sugar for `Scene[:Name1, :Name2]`
        @ref Expr1, Expr1 # Syntactic sugar for `(@ref Expr1, @ref Expr2)`
    ```
"""
macro ref(arg)
    extract_fields(arg)
end

macro ref(args...)
    Expr(:tuple, extract_fields.(args)...)
end

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

function GeometryTypes.widths(scene::Scene)
    widths(getscreen(scene))
end
