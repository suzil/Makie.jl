function shared_defaults(scene, kw_args)
    @defaults kw_args -> scene = begin
        visible = to_bool(true)
        transparency = to_bool(false)
        drawover = to_bool(false)
        show = to_bool(true)

        scale = to_scale(Vec3f0(1))
        offset = to_offset(Point3f0(0))
        rotation = to_rotation(Vec4f0(0, 0, 0, 1))

        model = calculated.to_modelmatrix(scale, offset, rotation)
    end
    kw_args
end

# @defaults function camera2d(scene, kw_args)
#     area = SimpleRectangle(0, 0, 500, 500)
#     projection = eye(Mat4f0)
#     view = eye(Mat4f0)
#
#     translationspeed = to_float(1)
#     eyeposition = Vec3f0(3)
#     lookat = Vec3f0(0)
#     upvector = Vec3f0((0, 0, 1))
#     near = to_float(10_000)
#     far = to_float(-10_000)
# end

function legend_shared(scene, kw_args)
    mm = 10
    @defaults kw_args -> scene.legendshared = begin
        backgroundcolor = to_color(:white)
        strokecolor = to_color(RGBA(0.3, 0.3, 0.3, 0.9))
        strokewidth = to_float(1mm)
        textgap = to_float(1.5mm)
        padding = to_2floats(1mm)
        outerpadding = to_2floats(1mm)
        align = to_textalign((:left, :hcenter))
        rotation = to_rotation(Vec4f0(0, 0, 0, 1))
        textcolor = to_color(:black)
        textsize = to_float(1.6mm)
    end
    kw_args
end

function legend_defaults(scene, kw_args)
    mm = 10
    @defaults kw_args -> scene.legend = begin
        position = to_position((0rel, 1rel))
        labelwidth = to_float(2mm)
        gap = to_float(2mm)
        markersize = to_markersize2d(0.5mm)
        linepattern = to_positions(Point2f0[(0, 0), (1, 0.0)])
        scatterpattern = to_positions(Point2f0[(0.5, 0.0)])

        backgroundcolor = to_color(theme.legendshared.backgroundcolor)
        strokecolor = to_color(theme.legendshared.strokecolor)
        strokewidth = to_float(theme.legendshared.strokewidth)
        textgap = to_float(theme.legendshared.textgap)
        padding = to_2floats(theme.legendshared.padding)
        outerpadding = to_2floats(theme.legendshared.outerpadding)
        align = to_textalign(theme.legendshared.align)
        rotation = to_rotation(theme.legendshared.rotation)
        textcolor = to_color(theme.legendshared.textcolor)
        textsize = to_float(theme.legendshared.textsize)
    end
    kw_args
end

function colorlegend_defaults(scene, kw_args)
    @defaults kw_args -> scene.color_legend = begin
        width = to_2floats((0.1rel, 0.4rel))
        position = to_position((1rel, 1rel))

        backgroundcolor = to_color(theme.legendshared.backgroundcolor)
        strokecolor = to_color(theme.legendshared.strokecolor)
        strokewidth = to_float(theme.legendshared.strokewidth)
        textgap = to_float(theme.legendshared.textgap)
        padding = to_2floats(theme.legendshared.padding)
        outerpadding = to_2floats(theme.legendshared.outerpadding)
        align = to_textalign(theme.legendshared.align)
        rotation = to_rotation(theme.legendshared.rotation)
        textcolor = to_color(theme.legendshared.textcolor)
        textsize = to_float(theme.legendshared.textsize)
    end
    kw_args
end

function contour_defaults(scene, kw_args)
    @defaults kw_args -> scene.contour = begin
        levels = to_float(5)
        color = to_color(theme.color)
        linewidth = to_float(1)
        fillrange = to_bool(false)
    end
    kw_args
end

# Note that this will create a function called surface_defaults
# This is not perfect, but for integrating this into the scene, it's the easiest to
# just have the default function name in the macro match the drawing function name.
function surface_defaults(scene, kw_args)
    @defaults kw_args -> scene.surface = begin
        x = to_surface(x)
        y = to_surface(y)
        z = to_surface(z)
        if haskeys(kw_args, :image)
            # needs no default, since it's guaranteed to be contained in kw_args
            image = to_image(image)
        elseif haskeys(kw_args, :color)
            color = to_color(color)
        else
            # in else block, so this is the default
            colormap = to_colormap(theme.colormap)
            # convert function should only have one argument right now, so we create this closure
            # colornorm defaults to nothing, which means it will be calculated from z
            cnorm_calc(scene, cnorm) = to_colornorm(scene, cnorm, z)
            colornorm = cnorm_calc(nothing)
        end
    end
    kw_args
end

function lines_defaults(scene, kw_args)
    position_share(scene, kw_args)
    @defaults kw_args -> scene.lines = begin
        if haskeys(kw_args, :intensity)
            colormap = to_colormap(theme.colormap)
            intensity = to_intensity(intensity)
            cnorm_calc(scene, cnorm) = to_colornorm(scene, cnorm, intensity)
            colornorm = cnorm_calc(nothing)
        else
            color = to_color(theme.color)
        end
        linewidth = to_float(theme.linewidth)
        linestyle = to_linestyle(nothing)
    end
    kw_args
end

function mesh_defaults(scene, kw_args)
    @defaults kw_args -> scene.mesh = begin
        attribute_id = to_attribut_id(nothing)
        color = to_color(theme.color)

        if haskeys(kw_args, :indices)
            indices = to_faces(indices)
            if haskeys(kw_args, :positions)
                positions = to_positions(positions)
            elseif haskeys(kw_args, :x, :y, :z)
                x = to_array(x)
                y = to_array(y)
                z = to_array(z)
                positions = calculated.to_positions(x, y, z)
            end
            mesh = calculated.to_mesh(positions, indices, color, attribute_id)
        else
            mesh = to_mesh(mesh)
        end
    end
    kw_args
end

function position_share(scene, kw_args)
    @defaults kw_args -> scene = begin
        if haskeys(kw_args, :x, :y, :z)
            x = to_array(x)
            y = to_array(y)
            z = to_array(z)
            positions = calculated.to_positions(x, y, z)
        elseif haskeys(kw_args, :x, :y)
            x = to_array(x)
            y = to_array(y)
            positions = calculated.to_positions(x, y)
        else
            positions = to_positions(positions)
        end
    end
    kw_args
end
function color_or_colormap(scene, kw_args, parent)
    @defaults kw_args -> scene.parent = begin
        # Either you give a color, or a colormap.
        # For a colormap, you'll also need intensities
        if haskeys(kw_args, :intensity)
            colormap = to_colormap(theme.colormap)
            intensity = to_intensity(intensity)
            cnorm_calc(scene, cnorm) = to_colornorm(scene, cnorm, intensity)
            colornorm = cnorm_calc(nothing)
        else
            color = to_color(theme.color)
        end
    end
    kw_args
end
function scatter_defaults(scene, kw_args)
    position_share(scene, kw_args)
    color_or_colormap(scene, kw_args, :scatter)

    @defaults kw_args -> scene.scatter = begin
        marker = to_spritemarker(Circle)

        strokecolor = to_color((:black, 0.0))
        strokewidth = to_float(0)

        glowcolor = to_color((:black, 0.0))
        glowwidth = to_float(0)

        markersize = to_markersize2d(0.1rel)

        rotations = to_rotations(Billboard())
    end
    kw_args
end

function meshscatter_defaults(scene, kw_args)
    position_share(scene, kw_args)
    color_or_colormap(scene, kw_args, :meshscatter)
    @defaults kw_args -> scene.meshscatter = begin
        marker = to_mesh(Sphere(Point3f0(0), 1f0))
        markersize = to_markersize3d(0.1rel)
        rotations = to_rotations(Vec4f0(0, 0, 0, 1))
    end
    kw_args
end

function image_defaults(scene, kw_args)
    @defaults kw_args -> scene.image = begin
        spatialorder = to_spatial_order(:yx)
        x = to_interval(x)
        y = to_interval(y)
        image = to_image(image)
    end
    kw_args
end

function volume_defaults(scene, kw_args)
    @defaults kw_args -> scene.volume = begin
        volume = to_array(volume)

        if haskeys(kw_args, :color)
            color = to_color(color)
        else
            colormap = to_colormap(theme.colormap)
            cnorm_calc(scene, cnorm) = to_colornorm(scene, cnorm, volume)
            colornorm = cnorm_calc(nothing)
        end

        algorithm = to_volume_algorithm(MaximumIntensityProjection)
        absorption = to_float(1f0)
        isovalue = to_float(0.5f0)
        isorange = to_float(0.01f0)
    end
    kw_args
end

function heatmap_defaults(scene, kw_args)
    @defaults kw_args -> scene.heatmap = begin
        heatmap = to_array(heatmap)

        linewidth = to_float(0f0)
        levels = to_float(0f0)

        colormap = to_colormap(theme.colormap)
        # convert function should only have one argument right now, so we create this closure
        colornorm = ((b, colornorm) -> to_colornorm(b, colornorm, heatmap))(nothing)
    end
    kw_args
end


function axis_defaults(scene, kw_args)

    q1 = qrotation(Vec3f0(1, 0, 0), -0.5f0*pi)
    q2 = qrotation(Vec3f0(0, 0, 1), 1f0*pi)
    tickrotations = (
        qrotation(Vec3f0(0,0,1), -1.5pi),
        q2,
        qmul(qmul(q2, q1), qrotation(Vec3f0(0, 1, 0), 1pi))
    )

    tickalign = (
        (:hcenter, :left), # x axis
        (:right, :vcenter), # y axis
        (:right, :vcenter), # z axis
    )
    dark_text = RGBAf0(0.0, 0.0, 0.0, 0.4)

    _scalefuncs = ntuple(i-> identity, 3)
    _gridthickness = ntuple(x-> 1f0, 3)
    _gridcolors = to_color(ntuple(x-> RGBAf0(0.5, 0.5, 0.5, 0.4), 3))
    _axiscolors = to_color(ntuple(x-> dark_text, 3))

    _axisnames = map(x-> ("$x Axis", 0.1, dark_text, Vec4f0(0,0,0,1), (:center, :bottom)), (:X, :Y, :Z))
    _showticks = ntuple(i-> true, 3)
    _tickfont3d = ntuple(i-> (0.1, RGBAf0(0.5, 0.5, 0.5, 0.6), tickrotations[i], tickalign[i]), 3)
    _tickfont2d = ntuple(i-> (0.1, RGBAf0(0.5, 0.5, 0.5, 0.6), Vec4f0(0,0,0,1), tickalign[i]), 2)
    _showaxis = ntuple(i-> true, 3)
    _showgrid = ntuple(i-> true, 3)

    @defaults kw_args -> scene.axis = begin
        axisnames = to_text(_axisnames)

        showticks = to_bool(_showticks)
        tickfont2d = to_font(_tickfont2d)
        tickfont3d = to_font(_tickfont3d)
        showaxis = to_bool(_showaxis)
        showgrid = to_bool(_showgrid)

        scalefuncs = to_scalefunc(_scalefuncs)
        gridcolors = to_color(_gridcolors)
        gridthickness = to_3floats(_gridthickness)
        axiscolors = to_color(_axiscolors)
    end
    kw_args
end

function text_defaults(scene, kw_args)
    @defaults kw_args -> scene.text = begin
        text = to_string(text)
        color = to_color(:black)
        strokecolor = to_color((:black, 0.0))
        strokewidth = to_float(0)
        font = to_font(GLVisualize.defaultfont())
        align = to_textalign((:left, :bottom))
        rotation = to_rotation(Vec4f0(0, 0, 0, 1))
        textsize = to_float(20)
        position = to_position(Point2f0(0))
    end
    kw_args
end
