using GLAbstraction, Makie, GeometryTypes
using GLAbstraction: orthographicprojection, translationmatrix
using StaticArrays

const AbstractCamera = Scene


function pixelcam(scene::Scene)
    screen = getscreen(scene)
    areanode = to_node(screen.area, FRect)
    cam = Scene(
        scene, Dict(
        :area => areanode,
        :projection => eye(Mat4f0),
        :view => eye(Mat4f0),
        :resolution => lift_node(x->Vec2f0(widths(x)), areanode),
        :scaling => Vec2f0(1)
    ))
    cam[:projectionview] = lift_node(*, cam, :projection, :view)
    # Initialize projection from the area
    update_cam!(cam, to_value(areanode))
    lift_node(areanode) do area
        x, y = minimum(area)
        w, h = widths(area) ./ 2f0
        cam[:projection] = orthographicprojection(-w, w, -h, h, -10_000f0, 10_000f0)
        cam[:view] = translationmatrix(Vec3f0(-x - w, -y - h, 0))
    end
    Canvas(screen, cam)
end

function camera2d(scene, area = nothing)
    rootcanv = to_value(getcanvas(scene, false))
    rootarea_s = rootcanv.screen.area
    rootarea = Reactive.value(rootarea_s)
    if area == nothing
        area = rootarea
    end
    area_pres = ratio_preserving_rect(area, rootarea)
    cam = Scene(
        scene, Dict(
        :area => lift_node(FRect, to_node(area_pres)),
        :projection => eye(Mat4f0),
        :view => eye(Mat4f0),
        :resolution => lift_node(x->Vec2f0(widths(x)), to_node(rootarea)),
        :scaling => Vec2f0(1)
    ))
    cam[:projectionview] = lift_node(*, cam, :projection, :view)
    # Initialize projection from the area
    Makie.update_cam!(cam, to_value(cam, :area))
    add_zoom(cam, scene)
    add_pan(cam, scene)
    canvas = Canvas(rootcanv.screen, cam)
    selection_rect(scene, canvas)
    canvas
end

function addcam(scat, cam::AbstractCamera)
    for robj in extract_renderable(Makie.native_visual(scat))
        robj[:view] = to_signal(cam[:view])
        robj[:projection] = to_signal(cam[:projection])
        robj[:projectionview] = to_signal(cam[:projectionview])
        robj[:resolution] = to_signal(cam[:resolution])
    end
end


wscale(screenrect, viewrect) = widths(viewrect) ./ widths(screenrect)

function update_cam!(cam::AbstractCamera, area)
    x, y = minimum(area)
    w, h = widths(area) ./ 2f0
    cam[:area] = FRect(area)
    cam[:projection] = orthographicprojection(-w, w, -h, h, -10_000f0, 10_000f0)
    cam[:view] = translationmatrix(Vec3f0(-x - w, -y - h, 0))
    return
end

function add_mousebuttons(scene::Scene)
    nw = GLWindow.nativewindow(getscreen(scene))
    scene[:mousebuttons] = Set(Mouse.Button[])
    GLFW.SetMouseButtonCallback(nw, (native_window, button, action, mods) -> begin
        set = to_value(scene, :mousebuttons)
        button_enum = Mouse.Button(button)
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
        scene[:mousebuttons] = set # trigger setfield event!
        return
    end)
    return
end

function camspace(cam_area, screen_area, point)
    point = point .* wscale(screen_area, cam_area)
    point .+ minimum(cam_area)
end

function selection_rect(
        scene, canvas,
        key = Mouse.left,
        button = Set([Keyboard.left_control, Keyboard.space])
    )
    rect = RefValue(FRect(0, 0, 0, 0))
    lw = 2f0
    rect_vis = lines(
        scene,
        name = :selection_rect,
        rect[],
        linestyle = :dot,
        thickness = 2f0,
        color = (:black, 0.4),
        transparency = false,
        drawover = true,
        canvas = canvas
    )
    cam = canvas.camera
    waspressed = RefValue(false)
    root = rootscene(scene)
    dragged_rect = lift_node(root, :mousedrag) do drag
        if ispressed(root, key) && ispressed(root, button)
            screen_area = to_value(root, :window_area)
            cam_area = to_value(cam, :area)
            mp = to_value(root, :mouseposition)
            mp = camspace(cam_area, screen_area, mp)

            if drag == Mouse.down
                waspressed[] = true
                rect_vis[:visible] = true # start displaying
                rect[] = FRect(mp, 0, 0)
                rect_vis[:positions] = rect[]
            elseif drag == Mouse.pressed
                mini = minimum(rect[])
                rect[] = FRect(mini, mp - mini)
                # mini, maxi = min(mini, mp), max(mini, mp)
                rect_vis[:positions] = rect[]
            end
        else
            if drag == Mouse.up && waspressed[]
                waspressed[] = false
                update_cam!(cam, rect[])
            end
            rect[] = FRect(0, 0, 0, 0)
            rect_vis[:positions] = rect[]
            # always hide if not the right key is pressed
            rect_vis[:visible] = false # hide
        end
        return rect[]
    end
    rect_vis, dragged_rect
end

function add_mousedrag(scene::Scene)
    indrag = RefValue(false)
    tracked_mousebutton = RefValue(Mouse.left)
    drag = RefValue(Mouse.notpressed)
    scene[:mousedrag] = lift_node(scene, :mouseposition, :mousebuttons) do mp, buttons
        # only track if still the same button is pressed
        if length(buttons) == 1 &&
                (!indrag[] || tracked_mousebutton[] == first(buttons))

            if !indrag[]
                tracked_mousebutton[] = first(buttons); indrag[] = true
                drag[] = Mouse.down # just started, so dragging is still false
                return drag[]
            else
                drag[] = Mouse.pressed
                return drag[]
            end
        end
        # already on notpressed, no need for update
        if drag[] != Mouse.notpressed
            drag[] = indrag[] ? Mouse.up : Mouse.notpressed
        end
        indrag[] = false
        return drag[]
    end
end

function add_pan(cam::AbstractCamera, scene)
    root = rootscene(scene)
    startpos = RefValue(Vec(0.0, 0.0))
    lift_node(root, :mouseposition, :mousedrag) do mp, dragging
        if ispressed(root, Mouse.middle)
            screen_area = to_value(root, :window_area)
            cam_area = to_value(cam, :area)
            if dragging == Mouse.down
                startpos[] = mp
            elseif dragging == Mouse.pressed && ispressed(root, Mouse.middle)
                diff = startpos[] .- mp
                startpos[] = mp
                diff = diff .* wscale(screen_area, cam_area)
                update_cam!(cam, FRect(minimum(cam_area) .+ diff, widths(cam_area)))
            end
        end
        return
    end
end

function add_zoom(cam::AbstractCamera, scene)
    root = rootscene(scene)
    lift_node(root[:scroll]) do x
        zoom = Float32(x[2])
        if zoom != 0
            a = to_value(cam, :area)
            z = 1 + (zoom * 0.10)
            mp = Vec2f0(to_value(root, :mouseposition))
            mp = (mp .* wscale(to_value(root, :window_area), a)) + minimum(a)
            p1, p2 = minimum(a), maximum(a)
            p1, p2 = p1 - mp, p2 - mp # translate to mouse position
            p1, p2 = z * p1, z * p2
            p1, p2 = p1 + mp, p2 + mp
            update_cam!(cam, FRect(p1, p2 - p1))
            z
        end
        return
    end
end

function ratio_preserving_widths(w1, w2)
    w2norm = normalize(w2)
    w2norm = reverse(maximum(w2norm) ./ w2norm)
    w2norm .* maximum(w1), w2norm
end

function ratio_preserving_rect(current::GeometryPrimitive, target::GeometryPrimitive)
    w1 = widths(current)
    w2 = widths(target)
    wr, w2norm = ratio_preserving_widths(w1, w2)
    FRect(minimum(current), wr)
end
function reset!(canvas, boundingbox, preserveratio = true)
    cam = canvas.camera
    w1 = widths(boundingbox)
    w2 = widths(canvas.pixel)
    wsame, w2norm = ratio_preserving_widths(w1, w2)
    if !preserveratio
        s = if w1[1] < w1[2]
            Vec2f0(wsame[1] / w1[1] / w2norm[1], 1)
        else
            Vec2f0(1, wsame[2] / w1[2] / w2norm[2])
        end
        cam[:scaling] = s
    end
    update_cam!(cam, FRect(minimum(boundingbox), wsame))
    return
end


lerp{T}(a::T, b::T, val::AbstractFloat) = (a .+ (val * (b .- a)))

function add_restriction!(cam::AbstractCamera, window, rarea::SimpleRectangle, minwidths::Vec)
    area_ref = Base.RefValue(cam[Area])
    restrict_action = paused_action(1.0) do t
        o = lerp(origin(area_ref[]), origin(cam[Area]), t)
        wh = lerp(widths(area_ref[]), widths(cam[Area]), t)
        update_cam!(cam, FRect(o, wh))
    end
    on(window, Mouse.Drag) do drag
        if drag == Mouse.up && !isplaying(restrict_action)
            area = cam[Area]
            o = origin(area)
            maxi = maximum(area)
            newo = max.(o, origin(rarea))
            newmax = min.(maxi, maximum(rarea))
            maxi = maxi - newmax
            newo = newo - maxi
            newwh = newmax - newo
            scale = 1f0
            for (w1, w2) in zip(minwidths, newwh)
                stmp = w1 > w2 ? w1 / w2 : 1f0
                scale = max(scale, stmp)
            end
            newwh = newwh * scale
            area_ref[] = FRect(newo, newwh)
            if area_ref[] != cam[Area]
                play!(restrict_action)
            end
        end
        return
    end
    restrict_action
end
