const render_task = RefValue{Task}()
function render_loop(tsig, screen, framerate = 1/60)
    while isopen(screen)
        t = time()
        GLWindow.poll_glfw() # GLFW poll
        if Base.n_avail(Reactive._messages) > 0
            render_frame(screen)
        end
        t = time() - t
        to_sleep = framerate - t
        if to_sleep > 0.001 # minimal sleep time
            sleep(to_sleep)
        end
    end
    GLWindow.destroy!(screen)
    return
end

function block(scene::Scene)
    wait(render_task[])
end


render_frame(scene::Scene) = render_frame(rootscreen(scene))
function render_frame(screen::GLWindow.Screen)
    GLWindow.reactive_run_till_now()
    GLWindow.render_frame(screen)
    GLWindow.swapbuffers(screen)
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
    scene
end
