
Theme(args::Pair...) = Theme(:theme, args...)

function Theme(name::Symbol, args::Pair...)
    dict = Dict{Symbol, Any}()
    for (k, v) in args
        if isa(v, Scene)
            dict[k] = v
        else
            dict[k] = to_node(v, identity, Any)
        end
    end
    Scene(dict, name)
end


function default_theme(scene)
    # Add all the internal defaults to the scene!
    scene[:theme] = Theme(
        :color => UniqueColorIter(:Set1),
        :linewidth => 1,
        :colormap => :YlGnBu,
        :shading => true,
        :light => [Vec3f0(1.0), Vec3f0(0.1), Vec3f0(0.9), Vec3f0(20)]
    )

    for func in (
            shared_defaults,
            legend_shared,
            legend_defaults,
            colorlegend_defaults,
            contour_defaults,
            surface_defaults,
            lines_defaults,
            mesh_defaults,
            scatter_defaults,
            meshscatter_defaults,
            image_defaults,
            volume_defaults,
            heatmap_defaults,
            axis_defaults,
            text_defaults
        )
        func(scene, nothing)
    end

end
