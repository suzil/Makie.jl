"""
Returns a signal, which is true as long as the window is open.
returns `Signal{Bool}`
[GLFW Docs](http://www.glfw.org/docs/latest/group__window.html#gaade9264e79fae52bdb78e2df11ee8d6a)
"""
function window_open(window::Window, scene::Scene)
    function windowclose(win)
        scene[:window_open] = false
    end
    scene[:window_open] = isopen(window)
    GLFW.SetWindowCloseCallback(window, windowclose)
end
function unsuscribe!(::typeof(window_open), window::Window, scene::Scene)
    GLFW.SetWindowCloseCallback(window, nothing)
end


"""
Size of window in pixel.
returns `Signal{Vec{2,Int}}`
[GLFW Docs](http://www.glfw.org/docs/latest/group__window.html#ga311bb32e578aa240b6464af494debffc)
"""
function window_size(window::Window, scene::Scene)
    function windowsize(window, w::Cint, h::Cint)
        scene[:window_size] = Int.((w, h))
    end
    scene[:window_size] = GLFW.GetFramebufferSize(window)
    GLFW.SetFramebufferSizeCallback(window, windowsize)
end
function unsuscribe!(::typeof(window_size), window::Window)
    GLFW.SetFramebufferSizeCallback(window, nothing)
end

"""
Position of the window in screen coordinates.
returns `Signal{Vec{2,Int}}`
[GLFW Docs](http://www.glfw.org/docs/latest/group__window.html#ga1c36e52549efd47790eb3f324da71924)
"""
function window_position(window::Window, scene::Scene)
    function windowposition(window, w::Cint, h::Cint)
        scene[:window_position] = Int.((w, h))
    end
    scene[:window_position] = GLFW.GetWindowPos(window)
    GLFW.SetWindowPosCallback(window, windowposition)
end
function unsuscribe!(::typeof(window_position), window::Window)
    GLFW.SetWindowPosCallback(window, nothing)
end

function addbuttons(scene, name, button, action, ::Type{ButtonEnum}) where ButtonEnum
    set = to_value(scene, name)
    button_enum = ButtonEnum(button)
    if button != GLFW.KEY_UNKNOWN
        if action == GLFW.PRESS
            push!(set, button_enum)
        elseif action == GLFW.RELEASE
            delete!(set, button_enum)
        elseif action == GLFW.REPEAT
            # nothing needs to be done, besides returning the same set of keys
        else
            error("Unrecognized enum value for GLFW button press action: $action")
        end
    end
    scene[name] = set # trigger setfield event!
    return
end

"""
Registers a callback for the mouse buttons + modifiers
returns `Signal{NTuple{4, Int}}`
[GLFW Docs](http://www.glfw.org/docs/latest/group__input.html#ga1e008c7a8751cea648c8f42cc91104cf)
"""
function mouse_buttons(window::Window, scene::Scene)
    scene[:mousebuttons] = Set(Mouse.Button[])
    function mousebuttons(native_window, button, action, mods)
        addbuttons(scene, :mousebuttons, button, action, Mouse.Button)
    end
    GLFW.SetMouseButtonCallback(window, mousebuttons)
end
function unsuscribe!(::typeof(mouse_buttons), window::Window)
    GLFW.SetMouseButtonCallback(window, nothing)
end

function keyboard_buttons(window::Window, scene::Scene)
    scene[:keyboardbuttons] = Set(Keyboard.Button[])
    function keyoardbuttons(window, button::Cint, scancode::Cint, action::Cint, mods::Cint)
        addbuttons(scene, :keyboardbuttons, button, action, Keyboard.Button)
    end
    GLFW.SetKeyCallback(window, keyoardbuttons)
end
function unsuscribe!(::typeof(keyboard_buttons), window::Window)
    GLFW.SetKeyCallback(window, nothing)
end

"""
Registers a callback for drag and drop of files.
returns `Signal{Vector{String}}`, which are absolute file paths
[GLFW Docs](http://www.glfw.org/docs/latest/group__input.html#gacc95e259ad21d4f666faa6280d4018fd)
"""
function dropped_files(window::Window, scene::Scene)
    function droppedfiles(window, files)
        scene[:droppedfiles] = String.(files)
    end
    scene[:droppedfiles] = String[]
    GLFW.SetDropCallback(window, droppedfiles)
end
function unsuscribe!(::typeof(dropped_files), window::Window)
    GLFW.SetDropCallback(window, nothing)
end


"""
Registers a callback for keyboard unicode input.
returns an `Signal{Vector{Char}}`,
containing the pressed char. Is empty, if no key is pressed.
[GLFW Docs](http://www.glfw.org/docs/latest/group__input.html#ga1e008c7a8751cea648c8f42cc91104cf)
"""
function unicode_input(window::Window, scene::Scene)
    function unicodeinput(window, c::Char)
        vals = to_value(scene, :unicode_input)
        push!(vals, c)
        scene[:unicode_input] = vals
        empty!(vals)
        scene[:unicode_input] = vals
    end
    x = Char[];sizehint!(x, 1)
    scene[:unicode_input] = x
    GLFW.SetCharCallback(window, unicodeinput)
end
function unsuscribe!(::typeof(unicode_input), window::Window)
    GLFW.SetCharCallback(window, nothing)
end

# TODO memoise? Or to bug ridden for the small performance gain?
function retina_scaling_factor(w, fb)
    (w[1] == 0 || w[2] == 0) && return (1.0, 1.0)
    fb ./ w
end
function retina_scaling_factor(window::Window)
    w, fb = GLFW.GetWindowSize(window), GLFW.GetFramebufferSize(window)
end

function correct_mouse(window::Window, w, h)
    w, fb = GLFW.GetWindowSize(window), GLFW.GetFramebufferSize(window)
    s = retina_scaling_factor(w, fb)
    (w, fb[2] - h) .* s
end

"""
Registers a callback for the mouse cursor position.
returns an `Signal{Vec{2, Float64}}`,
which is not in screen coordinates, with the upper left window corner being 0
[GLFW Docs](http://www.glfw.org/docs/latest/group__input.html#ga1e008c7a8751cea648c8f42cc91104cf)
"""
function mouse_position(window::Window, scene::Scene)
    function cursorposition(window, w::Cdouble, h::Cdouble)
        scene[:mouseposition] = correct_mouse(window, w, h)
    end
    scene[:mouseposition] = correct_mouse(window, GLFW.GetCursorPos(window)...)
    GLFW.SetCursorPosCallback(window, cursorposition)
end
function unsuscribe!(::typeof(mouse_position), window::Window)
    GLFW.SetCursorPosCallback(window, nothing)
end

"""
Registers a callback for the mouse scroll.
returns an `Signal{Vec{2, Float64}}`,
which is an x and y offset.
[GLFW Docs](http://www.glfw.org/docs/latest/group__input.html#gacc95e259ad21d4f666faa6280d4018fd)
"""
function scroll(window::Window, scene::Scene)
    function scrollcb(window, w::Cdouble, h::Cdouble)
        scene[:scroll] = (xoffset, yoffset)
        scene[:scroll] = (0.0, 0.0)
    end
    scene[:scroll] = (0.0, 0.0)
    GLFW.SetScrollCallback(window, scrollcb)
end
function unsuscribe!(::typeof(scroll), window::Window)
    GLFW.SetScrollCallback(window, nothing)
end

"""
Registers a callback for the focus of a window.
returns an `Signal{Bool}`,
which is true whenever the window has focus.
[GLFW Docs](http://www.glfw.org/docs/latest/group__window.html#ga6b5f973531ea91663ad707ba4f2ac104)
"""
function hasfocus(window::Window, scene::Scene)
    function hasfocuscb(window, focus::Bool)
        scene[:hasfocus] = focus
    end
    scene[:hasfocus] = false
    GLFW.SetWindowFocusCallback(window, hasfocuscb)
end
function unsuscribe!(::typeof(hasfocus), window::Window)
    GLFW.SetWindowFocusCallback(window, nothing)
end

"""
Registers a callback for if the mouse has entered the window.
returns an `Signal{Bool}`,
which is true whenever the cursor enters the window.
[GLFW Docs](http://www.glfw.org/docs/latest/group__input.html#ga762d898d9b0241d7e3e3b767c6cf318f)
"""
function entered_window(window::Window, scene::Scene)
    function enteredwindowcb(window, focus::Bool)
        scene[:entered_window] = focus
    end
    scene[:entered_window] = false
    GLFW.SetCursorEnterCallback(window, enteredwindowcb)
end

function unsuscribe!(::typeof(hasfocus), window::Window)
    GLFW.SetCursorEnterCallback(window, nothing)
end
