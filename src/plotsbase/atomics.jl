function expand_kwargs(scene, kw_args, name = :scene)
    # TODO get in all the shorthands from Plots.jl
    attributes = Scene(scene, Dict{Symbol, Any}(kw_args), name)
    shared_defaults(scene, attributes)
end

const atomic_funcs = (
    :contour => """
        contour(x, y, z)
    Creates a contour plot of the plane spanning x::Vector, y::Vector, z::Matrix
    """,
    :image => """
        image(x, y, image) / image(image)
    Plots an image on range x, y (defaults to dimensions)
    """,
    # could be implemented via image, but might be optimized specifically by the backend
    :heatmap => """
        heatmap(x, y, values) / heatmap(values)
    Plots a image on heatmap x, y (defaults to dimensions)
    """,
    :volume => """
        volume(volume_data)
    Plots a volume
    """,
    # alternatively, mesh2d?
    # :poly => """
    # """,
    :surface => """
        surface(x, y, z)
    Plots a surface, where x y z are supposed to lie on a grid
    """,
    :lines => """
        lines(x, y, z) / lines(x, y) / lines(positions)
    Plots a connected line for each element in xyz/positions
    """,
    :linesegment => """
        linesegment(x, y, z) / linesegment(x, y) / linesegment(positions)
    Plots a line for each pair of points in xyz/positions

    ## Attributes:

    The same as for [`lines`](@ref)
    """,
    # alternatively, mesh3d? Or having only mesh instead of poly + mesh and figure out 2d/3d via dispatch
    :mesh => """
        mesh(x, y, z) / mesh(mesh_object) / mesh(x, y, z, faces) / mesh(xyz, faces)
    Plots a 3D mesh
    """,
    :scatter => """
        scatter(x, y, z) / scatter(x, y) / scatter(positions)
    Plots a marker for each element in xyz/positions
    """,
    :meshscatter => """
        meshscatter(x, y, z) / meshscatter(x, y) / meshscatter(positions)
    Plots a mesh for each element in xyz/positions
    """,
    # :text => """
    # """,
    # Doesn't really need to be an atomic, could be implemented via lines
    :wireframe => """
        wireframe(x, y, z) / wireframe(positions) / wireframe(mesh)
    Draws a wireframe either interpreted as a surface or mesh
    """,

    :legend => """
        legend(series, labels)
    creates a legend from an array of plots and labels
    """,

    :axis => """
        axis(xrange, yrange, [zrange])

    Creates a axis from a x,y,z ranges
    """,

    :text => """
        text(string)

    Plots a text
    """
)


for (func, docstring) in atomic_funcs
    adoc = try
        f = eval(Symbol("$(func)_defaults"))
        sprint(x-> Markdown.plain(x, Docs.doc(f)))
    catch e
        ""
    end
    docstring = docstring * "\n\n ## Attributes:\n\n" * adoc
    @eval begin
        """
        $($(docstring))
        """
        function $func(a::T, args...; kw_args...) where T
            if !(T <: Scene)
                $func(get_global_scene(), a, args...; kw_args...)
            else
                # keyword argument signature should never contain the backend.
                # if so, it must come from the function defined below
                ts = join(typeof.(args), ", ")
                error("Signature $func($ts) is not implemented")
            end
        end
        function $func(scene::Scene, args...; kw_args...)
            $func(scene, args..., expand_kwargs(scene, kw_args, $(QuoteNode(func))))
        end
        export $func
    end
end


"""
Get's the function a scene got created with
"""
function plotfunction(scene::Scene)
    # TODO if we actually make new types per atomic primitive, we could do this performant and more elegantly
    scene.name == :scatter && return scatter
    scene.name == :lines && return lines
    scene.name == :linesegment && return linesegment
    scene.name == :mesh && return mesh
    scene.name == :poly && return poly
    scene.name == :surface && return surface
    scene.name == :wireframe && return wireframe
    scene.name == :image && return image
    scene.name == :heatmap && return heatmap
    scene.name == :volume && return volume
    scene.name == :meshscatter && return meshscatter
    error("$(scene.name) wasn't created by any plot command")
end


"""
Recreates a similar plot with new data
"""
function Base.similar(scene::Scene, newdata...; kw_args...)
    f = plotfunction(scene)
    p = parent(scene)
    attributes = expand_kwargs(scene, kw_args, scene.name)
    attributes = merge(scene, attributes)
    for elem in (:positions, :x, :y, :z)
        delete!(attributes, elem)
    end
    f(p, newdata..., attributes)
end



for func in (:image, :heatmap, :lines, :surface)
    # Higher level atomic signatures
    @eval begin
        function $func(scene::Scene, data::AbstractMatrix, attributes::Attributes)
            $func(scene, 1:size(data, 1), 1:size(data, 2), data, attributes)
        end
        function $func(scene::Scene, x::AbstractVector{T1}, y::AbstractVector{T2}, f::Function, attributes::Attributes) where {T1, T2}
            if !applicable(f, x[1], y[1])
                error("You need to pass a function like f(x::$T1, y::$T2). Found: $f")
            end
            T = typeof(f(x[1], y[1]))
            z = similar(x, T, (length(x), length(y)))
            z .= f.(x, y')
            $func(scene, x, y, z, attributes)
        end
    end
end
