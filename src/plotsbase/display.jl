const current_backend = Ref(:makie)


"""

scatter(args...; kwargs...) = plot(Scene{Scatter}(kw_args), args...)

root = plot() # returns rootscene
# root contains a theme, from which all defaults get feeded
# root also contains all window signals

root = plot(root, rand(10), thickness = 1mm) # creates a new node, inheriting from root
root = plot(rand(10), thickness = 1mm) # equal to the above
# -root
#     -p1
 # adds a new node to p1, inheriting attributes from p1
p1 = plot!(p1, rand(10)) # takes defaults from theme
# root
    # p1
        # p2
root = plot!(root, rand(10), p1, color = :red) # takes defaults from kw_args, then p1, then root.theme
# root
    # p1
        # p2
    # p3

# convenient way to access subplots
root[1] == p1
p1[1] == p2 && p2 == root[1][1]
root[2] == p3

pcombined = plot(root...) # equals to plot(root[1], root[2]) # equals to plot(p1, p3)
# pcombined
    # subplot1
        # p1
            # P2
    # subplot2
        # p3
#=
┏━━━━━━━┳━━━━━┓
┃ p1 p2 ┃ p3  ┃
┗━━━━━━━┻━━━━━┛
=#
pcombined == hbox(root...) # horizontal concat layout
pcombined == vbox(root...) # vertical concat layout

p2 = pop!(root[1]) # delete the last plot from (root[1] == p1)
layouted = vbox(hbox(root[1], p2), root[2]) # vertical + horizontal layout combined
# pcombined
    # subplot1 vertical
        # subplot 2 horizontal
            # p1
        # subplot 3 horizontal
            # p2
    # subplot2 vertical
        # p3
#=
┏━━━━┳━━━━┓
┃ p1 ┃ p2 ┃
┣━━━━┻━━━━┫
┃   p3    ┃
┗━━━━━━━━━┛
=#

p1 = root[1]
p3 = root[2]
layouted_axis = vbox(hbox(p1, plot(p2, axis = p2[:axis]), p3)) # vertical + horizontal layout combined

#=
┏━━━━┳━━━━┓
┃ p1 ┃ p2 ┃ # p1, p2 share the same axis object
┣━━━━┻━━━━┫
┃   p3    ┃
┗━━━━━━━━━┛
=#

# the above will all be backend independent!
display(layouted) # create the actual plot + window for the preferred + backend / display combo

disp = gl_display(resolution = ...) # explicitely chose a gl backend for display
display(disp, layouted)
"""
struct MDisplay{T} <: Base.Display
    area::NTuple{4, Float64}
    parent::Nullable{MDisplay{T}}
    children::Vector{MDisplay{T}}
    rendercontext::T
    # rootscene::Scene
end
function traverse(x, y)
    # error("Lol")
end
function Base.display(x::MDisplay, y)
    println("hehe")
    traverse(x, y)
    show(y)
end
disp = MDisplay((1.0,1.0,1.0,1.0), Nullable{MDisplay}(), MDisplay[], nothing)
pushdisplay(disp)
using Media
struct Lol end
# media(Lol, Media.Graphical)
setdisplay(Lol, disp)
function Media.render(x::MDisplay, y)
    println("hehe")
    traverse(x, y)
    show(y)
end
render_frame(scene::Scene) = render_frame(rootscreen(scene))
function render_frame(screen::GLWindow.Screen)
    GLWindow.reactive_run_till_now()
    GLWindow.render_frame(screen)
    GLWindow.swapbuffers(screen)
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
        scene[:canvas] = to_node(Canvas(w), identity, Any)
        add_mousebuttons(scene)
        add_mousedrag(scene)
        scene[:keyboardbuttons] = lift_node(scene[:buttons_pressed]) do x
            map(Keyboard.Button, x)
        end
        push!(global_scene, scene)
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
