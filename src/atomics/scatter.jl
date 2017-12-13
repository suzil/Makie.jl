using GeometryTypes, StaticArrays, Colors, GLAbstraction

"""
Hack to quickly make things more consistent inside Makie, without
changing GLVisualize too much! So we need to rewrite the attributes, the names and the
values a bit!
"""
function expand_for_glvisualize(kw_args)
    result = Dict{Symbol, Any}()
    drawover, transparency = false, false
    for (k, v) in kw_args
        k in (:marker, :positions, always_skip...) && continue
        if k == :drawover
            drawover = v
            continue
        end
        if k == :transparency
            transparency = v
            continue
        end
        if k == :rotations
            k = :rotation
            v = Vec4f0(0, 0, 0, 1)
            result[:billboard] = true
        end
        if k == :markersize
            k = :scale
        end
        if k == :glowwidth
            k = :glow_width
        end
        if k == :glowcolor
            k = :glow_color
        end
        if k == :strokewidth
            k = :stroke_width
        end
        if k == :strokecolor
            k = :stroke_color
        end
        if k == :positions
            k = :position
        end
        result[k] = to_typed_signal(v)
    end
    result[:prerender] = PreRender(drawover, transparency)
    result[:fxaa] = false
    result
end

function _scatter(scene, attributes)
    attributes = scatter_defaults(scene, attributes)
    gl_data = expand_for_glvisualize(attributes)
    shape = to_typed_signal(attributes[:marker])
    main = (shape, to_typed_signal(attributes[:positions]))
    data = GLVisualize.sprites(main, Style(:default), gl_data)
    attributes.visual[] = GLVisualize.assemble_shader(data).children[]
    insert_scene!(scene, attributes)
end

function mesh2glvisualize(kw_args)
    result = Dict{Symbol, Any}()
    for (k, v) in kw_args
        k in (:marker, :positions, always_skip...) && continue
        if k == :rotations
            k = :rotation
        end
        if k == :markersize
            k = :scale
        end
        if k == :positions
            k = :position
        end
        result[k] = to_typed_signal(v)
    end
    result[:fxaa] = true
    result
end

function _meshscatter(scene, kw_args)
    attributes = meshscatter_defaults(scene, kw_args)
    gl_data = mesh2glvisualize(attributes)
    shape = to_typed_signal(attributes[:marker])
    main = (shape, to_typed_signal(attributes[:positions]))
    viz = GLVisualize.meshparticle(main, Style(:default), gl_data)
    attributes.visual[] = GLVisualize.assemble_shader(viz).children[]
    insert_scene!(scene, attributes)
end

for arg in ((:x, :y), (:x, :y, :z), (:positions,))
    insert_expr = map(arg) do elem
        :(attributes[$(QuoteNode(elem))] = $elem)
    end
    @eval begin
        function scatter(scene::makie, $(arg...), attributes::Attributes)
            $(insert_expr...)
            _scatter(scene, attributes)
        end
        @eval begin
            function meshscatter(scene::makie, $(arg...), attributes::Attributes)
                $(insert_expr...)
                _meshscatter(scene, attributes)
            end
        end
    end
end
