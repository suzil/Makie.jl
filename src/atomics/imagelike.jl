function heatmap2glvisualize(attributes)
    result = Dict{Symbol, Any}()
    result[:stroke_width] = to_typed_signal(attributes[:linewidth])
    result[:levels] = to_typed_signal(attributes[:levels])

    result[:color_norm] = to_typed_signal(attributes[:colornorm])
    result[:color_map] = to_typed_signal(attributes[:colormap])

    heatmap = to_typed_signal(lift_node(attributes[:heatmap]) do z
        [GLVisualize.Intensity{Float32}(z[j, i]) for i = 1:size(z, 2), j = 1:size(z, 1)]
    end)
    tex = GLAbstraction.Texture(value(heatmap), minfilter = :nearest)
    foreach(heatmap) do x
        update!(tex, x)
    end
    result, tex
end

function heatmap(scene::makie, x, y, z, attributes::Attributes)
    attributes[:x] = x
    attributes[:y] = y
    attributes[:heatmap] = z
    attributes = heatmap_defaults(scene, attributes)
    gl_data, tex = heatmap2glvisualize(attributes)
    attributes.visual[] = visualize(tex, Style(:default), gl_data).children[]
    insert_scene!(scene, attributes)
end


function image2glvisualize(attributes)
    result = Dict{Symbol, Any}()
    result[:primitive] = to_typed_signal(lift_node(getindex.(attributes, (:x, :y, :spatialorder))...) do x, y, so
        if so != "xy"
            y, x = x, y
        end
        xmin, ymin = minimum(x), minimum(y)
        xmax, ymax = maximum(x), maximum(y)
        SimpleRectangle{Float32}(xmin, ymin, xmax - xmin, ymax - ymin)
    end)
    result[:spatialorder] = to_value(attributes[:spatialorder])
    result[:model] = to_typed_signal(attributes[:model])
    result[:fxaa] = false
    result
end

function image(scene::makie, x, y, img, attributes::Attributes)
    attributes[:x] = x
    attributes[:y] = y
    attributes[:image] = img
    attributes = image_defaults(scene, attributes)
    gl_data = image2glvisualize(attributes)
    attributes.visual[] = visualize(to_typed_signal(attributes[:image]), Style(:default), gl_data).children[]
    insert_scene!(scene, attributes)
end

function volume2glvisualize(attributes)
    result = Dict{Symbol, Any}()
    if haskey(attributes, :colornorm)
        result[:color_norm] = to_typed_signal(attributes[:colornorm])
        result[:color_map] = to_typed_signal(attributes[:colormap])
    else
        result[:color_map] = nothing
        result[:color_norm] = nothing
        result[:color] = to_typed_signal(attributes[:color])
    end

    result[:algorithm] = to_typed_signal(attributes[:algorithm])
    result[:isovalue] = to_typed_signal(attributes[:isovalue])
    result[:isorange] = to_typed_signal(attributes[:isorange])
    result[:absorption] = to_typed_signal(attributes[:absorption])

    result
end

function volume(scene::makie, vol, attributes::Attributes)
    attributes[:volume] = vol
    attributes = volume_defaults(scene, attributes)
    gl_data = volume2glvisualize(attributes)
    attributes.visual[] = visualize(to_typed_signal(attributes[:volume]), Style(:default), gl_data).children[]
    insert_scene!(scene, attributes)
end
