# Makie examples

```Julia
using Makie
# work around the fact that nextjournal doesn't have display incorperated correctly
output(x::String) = cp(x, "/results/$(basename(x))")
output(x::Scene) = Makie.save("/results/test.png", x)
function output(x::Stepper)
    for file in readdir(x.path)
        cp(joinpath(x.path, file), "/results/")
    end
end

```

## Test heatmap + image overlap

```julia
using Makie

result = let
    heatmap(rand(32, 32))
    image!(map(x->RGBAf0(x,0.5, 0.5, 0.8), rand(32,32)))

end
output(result)

```

## Interaction

```julia
using Makie

result = let
    scene = Scene(resolution = (500, 500))

    f(t, v, s) = (sin(v + t) * s, cos(v + t) * s)
    time = Node(0.0)
    p1 = scatter!(scene, lift(t-> f.(t, linspace(0, 2pi, 50), 1), time))[end]
    p2 = scatter!(scene, lift(t-> f.(t * 2.0, linspace(0, 2pi, 50), 1.5), time))[end]
    lines = lift(p1[1], p2[1]) do pos1, pos2
        map((a, b)-> (a, b), pos1, pos2)
    end
    linesegments!(scene, lines)
    N = 150
    record(scene, "/results/interaction.gif", linspace(0, 10, N)) do i
        push!(time, i)
   end

end
output(result)

```

## barplot

```julia
using Makie

result = let
    barplot(rand(10), color = rand(10))
    # barplot(rand(3), color = [:red, :blue, :green])

end
output(result)

```

## quiver

```julia
using Makie
 using ImageFiltering

result = let
    x = linspace(-2, 2, 21)
    y = x
    z = x .* exp.(-x .^ 2 .- (y') .^ 2)
    scene = contour(x, y, z, levels = 10, linewidth = 3)
    u, v = ImageFiltering.imgradients(z, KernelFactors.ando3)
    arrows!(x, y, u, v, arrowsize = 0.05)

end
output(result)

```

## image

```julia
using Makie

result = let
    AbstractPlotting.vbox(
        image(Makie.logo(), scale_plot = false),
        image(rand(100, 500), scale_plot = false),
    )


end
output(result)

```

## scatter colormap

```julia
using Makie

result = let
    scatter(rand(10), rand(10), color = rand(10))

end
output(result)

```

## FEM polygon 2D

```julia
using Makie

result = let
    coordinates = [
        0.0 0.0;
        0.5 0.0;
        1.0 0.0;
        0.0 0.5;
        0.5 0.5;
        1.0 0.5;
        0.0 1.0;
        0.5 1.0;
        1.0 1.0;
    ]
    connectivity = [
        1 2 5;
        1 4 5;
        2 3 6;
        2 5 6;
        4 5 8;
        4 7 8;
        5 6 9;
        5 8 9;
    ]
    color = [0.0, 0.0, 0.0, 0.0, -0.375, 0.0, 0.0, 0.0, 0.0]
    poly(coordinates, connectivity, color = color, strokecolor = (:black, 0.6), strokewidth = 4)

end
output(result)

```

## FEM mesh 2D

```julia
using Makie

result = let
    coordinates = [
        0.0 0.0;
        0.5 0.0;
        1.0 0.0;
        0.0 0.5;
        0.5 0.5;
        1.0 0.5;
        0.0 1.0;
        0.5 1.0;
        1.0 1.0;
    ]
    connectivity = [
        1 2 5;
        1 4 5;
        2 3 6;
        2 5 6;
        4 5 8;
        4 7 8;
        5 6 9;
        5 8 9;
    ]
    color = [0.0, 0.0, 0.0, 0.0, -0.375, 0.0, 0.0, 0.0, 0.0]
    scene = mesh(coordinates, connectivity, color = color, shading = false)
    wireframe!(scene[end][1], color = (:black, 0.6), linewidth = 3)

end
output(result)

```

## colored triangle

```julia
using Makie

result = let
    mesh(
        [(0.0, 0.0), (0.5, 1.0), (1.0, 0.0)], color = [:red, :green, :blue],
        shading = false
    )

end
output(result)

```

## heatmap interpolation

```julia
using Makie

result = let
    p1 = heatmap(rand(100, 50), interpolate = true)
    p2 = heatmap(rand(100, 50), interpolate = false)
    scene = AbstractPlotting.vbox(p1, p2)
    text!(campixel(p1), "Interpolate = true", position = widths(p1) .* Vec(0.5, 1), align = (:center, :top), raw = true)
    text!(campixel(p2), "Interpolate = false", position = widths(p2) .* Vec(0.5, 1), align = (:center, :top), raw = true)
    scene

end
output(result)

```

## colored triangle

```julia
using Makie

result = let
    poly(
        [(0.0, 0.0), (0.5, 1.0), (1.0, 0.0)],
        color = [:red, :green, :blue],
        strokecolor = :black, strokewidth = 2
    )

end
output(result)

```

## Subscenes

```julia
using Makie

result = let
    img = rand(RGBAf0, 100, 100)
    scene = image(img, show_axis = false)
    subscene = Scene(scene, IRect(100, 100, 300, 300))
    scatter!(subscene, rand(100) * 200, rand(100) * 200, markersize = 4)
    scene

end
output(result)

```

## Polygons

```julia
using Makie
using GeometryTypes

result = let
    scene = Scene(resolution = (500, 500))
    points = decompose(Point2f0, Circle(Point2f0(50), 50f0))
    pol = poly!(scene, points, color = :gray, strokewidth = 10, strokecolor = :red)
    # Optimized forms
    poly!(scene, [Circle(Point2f0(50+300), 50f0)], color = :gray, strokewidth = 10, strokecolor = :red)
    poly!(scene, [Circle(Point2f0(50+i, 50+i), 10f0) for i = 1:100:400], color = :red)
    poly!(scene, [Rectangle{Float32}(50+i, 50+i, 20, 20) for i = 1:100:400], strokewidth = 2, strokecolor = :green)
    linesegments!(scene,
        [Point2f0(50 + i, 50 + i) => Point2f0(i + 70, i + 70) for i = 1:100:400], linewidth = 8, color = :purple
    )

end
output(result)

```

## Contour Function

```julia
using Makie

result = let
    r = linspace(-10, 10, 512)
    z = ((x, y)-> sin(x) + cos(y)).(r, r')
    contour(r, r, z, levels = 5, color = :viridis, linewidth = 3)

end
output(result)

```

## contour

```julia
using Makie

result = let
    y = linspace(-0.997669, 0.997669, 23)
    contour(linspace(-0.99, 0.99, 23), y, rand(23, 23), levels = 10)

end
output(result)

```

## Heatmap

```julia
using Makie

result = let
    heatmap(rand(32, 32))

end
output(result)

```

## Animated Scatter

```julia
using Makie

result = let
    N = 10
    r = [(rand(7, 2) .- 0.5) .* 25 for i = 1:N]
    scene = scatter(r[1][:, 1], r[1][:, 2], markersize = 1, limits = FRect(-25/2, -25/2, 25, 25))
    s = scene[end] # last plot in scene
    record(scene, "/results/animated_scatter.gif", r) do m
        s[1] = m[:, 1]
        s[2] = m[:, 2]
   end

end
output(result)

```

## Text Annotation

```julia
using Makie

result = let
    text(
        ". This is an annotation!",
        position = (300, 200),
        align = (:center,  :center),
        textsize = 60,
        font = "Blackchancery"
    )

end
output(result)

```

## Text rotation

```julia
using Makie

result = let
    scene = Scene(resolution = (500, 500))
    pos = (500, 500)
    posis = Point2f0[]
    for r in linspace(0, 2pi, 20)
        p = pos .+ (sin(r)*100.0, cos(r) * 100)
        push!(posis, p)
        t = text!(
            scene, "test",
            position = p,
            textsize = 50,
            rotation = 1.5pi - r,
            align = (:center, :center)
        )
    end
    scatter!(scene, posis, markersize = 10)

end
output(result)

```

## Volume Function

```julia
using Makie

result = let
    volume(rand(32, 32, 32), algorithm = :mip)

end
output(result)

```

## Textured Mesh

```julia
using Makie
 using FileIO

result = let
    scene = Scene(resolution = (500, 500))
    catmesh = FileIO.load(Makie.assetpath("cat.obj"), GLNormalUVMesh)
    mesh(catmesh, color = Makie.loadasset("diffusemap.tga"))

end
output(result)

```

## Load Mesh

```julia
using Makie

result = let
    mesh(Makie.loadasset("cat.obj"))

end
output(result)

```

## Colored Mesh

```julia
using Makie

result = let
    x = [0, 1, 2, 0]
    y = [0, 0, 1, 2]
    z = [0, 2, 0, 1]
    color = [:red, :green, :blue, :yellow]
    i = [0, 0, 0, 1]
    j = [1, 2, 3, 2]
    k = [2, 3, 1, 3]
    # indices interpreted as triangles (every 3 sequential indices)
    indices = [1, 2, 3,   1, 3, 4,   1, 4, 2,   2, 3, 4]
    mesh(x, y, z, indices, color = color)

end
output(result)

```

## Wireframe of a Mesh

```julia
using Makie

result = let
    wireframe(Makie.loadasset("cat.obj"))

end
output(result)

```

## Wireframe of Sphere

```julia
using Makie

result = let
    wireframe(Sphere(Point3f0(0), 1f0))

end
output(result)

```

## Wireframe of a Surface

```julia
using Makie

result = let
    function xy_data(x, y)
        r = sqrt(x^2 + y^2)
        r == 0.0 ? 1f0 : (sin(r)/r)
    end
    N = 30
    lspace = linspace(-10, 10, N)
    z = Float32[xy_data(x, y) for x in lspace, y in lspace]
    range = linspace(0, 3, N)
    wireframe(range, range, z)

end
output(result)

```

## Surface

```julia
using Makie

result = let
    N = 30
    function xy_data(x, y)
        r = sqrt(x^2 + y^2)
        r == 0.0 ? 1f0 : (sin(r)/r)
    end
    lspace = linspace(-10, 10, N)
    z = Float32[xy_data(x, y) for x in lspace, y in lspace]
    range = linspace(0, 3, N)
    surface(
        range, range, z,
        colormap = :Spectral
    )

end
output(result)

```

## Surface with image

```julia
using Makie

result = let
    N = 30
    function xy_data(x, y)
        r = sqrt(x^2 + y^2)
        r == 0.0 ? 1f0 : (sin(r)/r)
    end
    r = linspace(-2, 2, N)
    surf_func(i) = [Float32(xy_data(x*i, y*i)) for x = r, y = r]
    surface(
        r, r, surf_func(10),
        color = rand(RGBAf0, 124, 124)
    )

end
output(result)

```

## Line Function

```julia
using Makie

result = let
    scene = Scene()
    x = linspace(0, 3pi)
    lines!(scene, x, sin.(x))
    lines!(scene, x, cos.(x), color = :blue)

end
output(result)

```

## Meshscatter Function

```julia
using Makie
 using GeometryTypes

result = let
    large_sphere = Sphere(Point3f0(0), 1f0)
    positions = decompose(Point3f0, large_sphere)
    colS = [RGBAf0(rand(), rand(), rand(), 1.0) for i = 1:length(positions)]
    sizesS = [rand(Point3f0) .* 0.05f0 for i = 1:length(positions)]
    meshscatter(positions, color = colS, markersize = sizesS)

end
output(result)

```

## scatter

```julia
using Makie

result = let
    scatter(rand(20), rand(20), markersize = 0.03)

end
output(result)

```

## Marker sizes

```julia
using Makie

result = let
    scatter(rand(20), rand(20), markersize = rand(20)./20, color = to_colormap(:Spectral, 20))

end
output(result)

```

## Record Video

```julia
using Makie

result = let
    scene = Scene()

    f(t, v, s) = (sin(v + t) * s, cos(v + t) * s, (cos(v + t) + sin(v)) * s)
    t = Node(Base.time()) # create a life signal
    limits = FRect3D(Vec3f0(-1.5, -1.5, -3), Vec3f0(3, 3, 6))
    p1 = meshscatter!(scene, lift(t-> f.(t, linspace(0, 2pi, 50), 1), t), markersize = 0.05)[end]
    p2 = meshscatter!(scene, lift(t-> f.(t * 2.0, linspace(0, 2pi, 50), 1.5), t), markersize = 0.05)[end]

    lines = lift(p1[1], p2[1]) do pos1, pos2
        map((a, b)-> (a, b), pos1, pos2)
    end
    linesegments!(scene, lines, linestyle = :dot, limits = limits)
    # record a video
    N = 150
    record(scene, "/results/record_video.gif", 1:N) do i
        push!(t, Base.time())
   end

end
output(result)

```

## 3D Contour with 2D contour slices

```julia
using Makie

result = let
    function test(x, y, z)
        xy = [x, y, z]
        ((xy') * eye(3, 3) * xy) / 20
    end
    x = linspace(-2pi, 2pi, 100)
    scene = Scene()
    c = contour!(scene, x, x, x, test, levels = 6, alpha = 0.3)[end]
    xm, ym, zm = minimum(scene.limits[])
    # c[4] == fourth argument of the above plotting command
    contour!(scene, x, x, map(v-> v[1, :, :], c[4]), transformation = (:xy, zm), linewidth = 10)
    heatmap!(scene, x, x, map(v-> v[:, 1, :], c[4]), transformation = (:xz, ym))
    contour!(scene, x, x, map(v-> v[:, :, 1], c[4]), fillrange = true, transformation = (:yz, xm))

end
output(result)

```

## Contour3d

```julia
using Makie

result = let
    function xy_data(x, y)
        r = sqrt(x*x + y*y)
        r == 0.0 ? 1f0 : (sin(r)/r)
    end
    r = linspace(-1, 1, 100)
    contour3d(r, r, (x,y)-> xy_data(10x, 10y), levels = 20, linewidth = 3)

end
output(result)

```

## Arrows 3D

```julia
using Makie

result = let
    function SphericalToCartesian(r::T,θ::T,ϕ::T) where T<:AbstractArray
        x = @.r*sin(θ)*cos(ϕ)
        y = @.r*sin(θ)*sin(ϕ)
        z = @.r*cos(θ)
        Point3f0.(x, y, z)
    end
    n = 100^2 #number of points to generate
    r = ones(n);
    θ = acos.(1 .- 2 .* rand(n))
    φ = 2π * rand(n)
    pts = SphericalToCartesian(r,θ,φ)
    arrows(pts, (normalize.(pts) .* 0.1f0), arrowsize = 0.02, linecolor = :green, arrowcolor = :darkblue)

end
output(result)

```

## Image on Surface Sphere

```julia
using Makie

result = let
    n = 20
    θ = [0;(0.5:n-0.5)/n;1]
    φ = [(0:2n-2)*2/(2n-1);2]
    x = [cospi(φ)*sinpi(θ) for θ in θ, φ in φ]
    y = [sinpi(φ)*sinpi(θ) for θ in θ, φ in φ]
    z = [cospi(θ) for θ in θ, φ in φ]
    rand([-1f0, 1f0], 3)
    pts = vec(Point3f0.(x, y, z))
    surface(x, y, z, color = Makie.logo())

end
output(result)

```

## Arrows on Sphere

```julia
using Makie

result = let
    n = 20
    f   = (x,y,z) -> x*exp(cos(y)*z)
    ∇f  = (x,y,z) -> Point3f0(exp(cos(y)*z), -sin(y)*z*x*exp(cos(y)*z), x*cos(y)*exp(cos(y)*z))
    ∇ˢf = (x,y,z) -> ∇f(x,y,z) - Point3f0(x,y,z)*dot(Point3f0(x,y,z), ∇f(x,y,z))

    θ = [0;(0.5:n-0.5)/n;1]
    φ = [(0:2n-2)*2/(2n-1);2]
    x = [cospi(φ)*sinpi(θ) for θ in θ, φ in φ]
    y = [sinpi(φ)*sinpi(θ) for θ in θ, φ in φ]
    z = [cospi(θ) for θ in θ, φ in φ]

    pts = vec(Point3f0.(x, y, z))
    ∇ˢF = vec(∇ˢf.(x, y, z)) .* 0.1f0
    surface(x, y, z)
    arrows!(
        pts, ∇ˢF,
        arrowsize = 0.03, linecolor = (:white, 0.6), linewidth = 3
    )

end
output(result)

```

## surface + contour3d

```julia
using Makie

result = let
    vx = -1:0.01:1
    vy = -1:0.01:1

    f(x, y) = (sin(x*10) + cos(y*10)) / 4

    p1 = surface(vx, vy, f)
    p2 = contour3d(vx, vy, (x, y) -> f(x,y), levels = 15, linewidth = 3)

    scene = AbstractPlotting.vbox(p1, p2)
    text!(campixel(p1), "surface", position = widths(p1) .* Vec(0.5, 1), align = (:center, :top), raw = true)
    text!(campixel(p2), "contour3d", position = widths(p2) .* Vec(0.5, 1), align = (:center, :top), raw = true)
    scene

end
output(result)

```

## FEM mesh 3D

```julia
using Makie
 using GeometryTypes

result = let
    cat = Makie.loadasset("cat.obj")
    vertices = decompose(Point3f0, cat)
    faces = decompose(Face{3, Int}, cat)
    coordinates = [vertices[i][j] for i = 1:length(vertices), j = 1:3]
    connectivity = [faces[i][j] for i = 1:length(faces), j = 1:3]
    mesh(
        coordinates, connectivity,
        color = rand(length(vertices))
    )

end
output(result)

```

## Axis + Surface

```julia
using Makie

result = let
    vx = -1:0.01:1
    vy = -1:0.01:1

    f(x, y) = (sin(x*10) + cos(y*10)) / 4
    scene = Scene(resolution = (500, 500))
    # One way to style the axis is to pass a nested dictionary / named tuple to it.
    surface!(scene, vx, vy, f, axis = NT(frame = NT(linewidth = 2.0)))
    psurf = scene[end] # the surface we last plotted to scene
    # One can also directly get the axis object and manipulate it
    axis = scene[Axis] # get axis

    # You can access nested attributes likes this:
    axis[:names, :axisnames] = ("\\bf{ℜ}[u]", "\\bf{𝕴}[u]", " OK\n\\bf{δ}\n γ")
    tstyle = axis[:names] # or just get the nested attributes and work directly with them

    tstyle[:textsize] = 10
    tstyle[:textcolor] = (:red, :green, :black)
    tstyle[:font] = "helvetica"


    psurf[:colormap] = :RdYlBu
    wh = widths(scene)
    t = text!(
        campixel(scene),
        "Multipole Representation of first resonances of U-238",
        position = (wh[1] / 2.0, wh[2] - 20.0),
        align = (:center,  :center),
        textsize = 20,
        font = "helvetica",
        raw = :true
    )
    c = lines!(scene, Circle(Point2f0(0.1, 0.5), 0.1f0), color = :red, offset = Vec3f0(0, 0, 1))
    scene
    #update surface
    # TODO explain and improve the situation here
    psurf.converted[3][] = f.(vx .+ 0.5, (vy .+ 0.5)')
    scene

end
output(result)

```

## Fluctuation 3D

```julia
using Makie
 using GeometryTypes, Colors

result = let
    scene = Scene()
    # define points/edges
    perturbfactor = 4e1
    N = 3; nbfacese = 30; radius = 0.02
    large_sphere = Sphere(Point3f0(0), 1f0)
    positions = decompose(Point3f0, large_sphere, 30)
    np = length(positions)
    pts = [positions[k][l] for k = 1:length(positions), l = 1:3]
    pts = vcat(pts, 1.1 * pts + randn(size(pts)) / perturbfactor) # light position influence ?
    edges = hcat(collect(1:np), collect(1:np) + np)
    ne = size(edges, 1); np = size(pts, 1)
    # define markers meshes
    meshC = GLNormalMesh(
        Makie.Cylinder{3, Float32}(
            Point3f0(0., 0., 0.),
            Point3f0(0., 0, 1.),
            Float32(1)
        ), nbfacese
    )
    meshS = GLNormalMesh(large_sphere, 20)
    # define colors, markersizes and rotations
    pG = [Point3f0(pts[k, 1], pts[k, 2], pts[k, 3]) for k = 1:np]
    lengthsC = sqrt.(sum((pts[edges[:,1], :] .- pts[edges[:, 2], :]) .^ 2, 2))
    sizesC = [Vec3f0(radius, radius, lengthsC[i]) for i = 1:ne]
    sizesC = [Vec3f0(1., 1., 1.) for i = 1:ne]
    colorsp = [RGBA{Float32}(rand(), rand(), rand(), 1.) for i = 1:np]
    colorsC = [(colorsp[edges[i, 1]] + colorsp[edges[i, 2]]) / 2. for i = 1:ne]
    sizesC = [Vec3f0(radius, radius, lengthsC[i]) for i = 1:ne]
    Qlist = zeros(ne, 4)
    for k = 1:ne
        ct = GeometryTypes.Cylinder{3, Float32}(
            Point3f0(pts[edges[k, 1], 1], pts[edges[k, 1], 2], pts[edges[k, 1], 3]),
            Point3f0(pts[edges[k, 2], 1], pts[edges[k, 2], 2], pts[edges[k, 2], 3]),
            Float32(1)
        )
        Q = GeometryTypes.rotation(ct)
        r = 0.5 * sqrt(1 + Q[1, 1] + Q[2, 2] + Q[3, 3]); Qlist[k, 4] = r
        Qlist[k, 1] = (Q[3, 2] - Q[2, 3]) / (4 * r)
        Qlist[k, 2] = (Q[1, 3] - Q[3, 1]) / (4 * r)
        Qlist[k, 3] = (Q[2, 1] - Q[1, 2]) / (4 * r)
    end
    rotationsC = [Makie.Vec4f0(Qlist[i, 1], Qlist[i, 2], Qlist[i, 3], Qlist[i, 4]) for i = 1:ne]
    # plot
    hm = meshscatter!(
        scene, pG[edges[:, 1]],
        color = colorsC, marker = meshC,
        markersize = sizesC,  rotations = rotationsC,
    )
    hp = meshscatter!(
        scene, pG,
        color = colorsp, marker = meshS, markersize = radius,
    )

end
output(result)

```

## Connected Sphere

```julia
using Makie

result = let
    large_sphere = Sphere(Point3f0(0), 1f0)
    positions = decompose(Point3f0, large_sphere)
    linepos = view(positions, rand(1:length(positions), 1000))
    scene = lines(linepos, linewidth = 0.1, color = :black)
    scatter!(scene, positions, strokewidth = 10, strokecolor = :white, color = RGBAf0(0.9, 0.2, 0.4, 0.6))
    scene

end
output(result)

```

## image scatter

```julia
using Makie

result = let
    scatter(
        1:10, 1:10, rand(10, 10) .* 10,
        rotations = normalize.(rand(Quaternionf0, 10*10)),
        markersize = 1,
        # can also be an array of images for each point
        # need to be the same size for best performance, though
        marker = Makie.logo()
    )

end
output(result)

```

## Simple meshscatter

```julia
using Makie

result = let
    large_sphere = Sphere(Point3f0(0), 1f0)
    positions = decompose(Point3f0, large_sphere)
    meshscatter(positions, color = RGBAf0(0.9, 0.2, 0.4, 1), markersize = 0.05)

end
output(result)

```

## Animated surface and wireframe

```julia
using Makie

result = let
    scene = Scene();
    function xy_data(x, y)
        r = sqrt(x^2 + y^2)
        r == 0.0 ? 1f0 : (sin(r)/r)
    end

    r = linspace(-2, 2, 50)
    surf_func(i) = [Float32(xy_data(x*i, y*i)) for x = r, y = r]
    z = surf_func(20)
    surf = surface!(scene, r, r, z)[end]

    wf = wireframe!(scene, r, r, Makie.lift(x-> x .+ 1.0, surf[3]),
        linewidth = 2f0, color = Makie.lift(x-> to_colormap(x)[5], surf[:colormap])
    )
    N = 150
    scene
    record(scene, "/results/animated_surface_and_wireframe.gif", linspace(5, 40, N)) do i
        surf[3] = surf_func(i)
   end

end
output(result)

```

## Normals of a Cat

```julia
using Makie

result = let
    x = Makie.loadasset("cat.obj")
    mesh(x, color = :black)
    pos = map(x.vertices, x.normals) do p, n
        p => p .+ (normalize(n) .* 0.05f0)
    end
    linesegments!(pos, color = :blue)

end
output(result)

```

## Sphere Mesh

```julia
using Makie

result = let
    mesh(Sphere(Point3f0(0), 1f0), color = :blue)

end
output(result)

```

## Stars

```julia
using Makie

result = let
    stars = 100_000
    scene = Scene(backgroundcolor = :black)
    scatter!(
        scene,
        (rand(Point3f0, stars) .- 0.5) .* 10,
        glowwidth = 0.005, glowcolor = :white, color = RGBAf0(0.8, 0.9, 0.95, 0.4),
        markersize = rand(linspace(0.0001, 0.01, 100), stars),
        show_axis = false
    )
    update_cam!(scene, FRect3D(Vec3f0(-2), Vec3f0(4)))
    scene

end
output(result)

```

## Unicode Marker

```julia
using Makie

result = let
    scene = Scene(resolution = (500, 500))
    scatter!(scene, Point3f0[(1,0,0), (0,1,0), (0,0,1)], marker = [:x, :circle, :cross])

end
output(result)

```

## Merged color Mesh

```julia
using Makie
 using GeometryTypes

result = let
    x = Vec3f0(0); baselen = 0.2f0; dirlen = 1f0
    # create an array of differently colored boxes in the direction of the 3 axes
    rectangles = [
        (HyperRectangle(Vec3f0(x), Vec3f0(dirlen, baselen, baselen)), RGBAf0(1,0,0,1)),
        (HyperRectangle(Vec3f0(x), Vec3f0(baselen, dirlen, baselen)), RGBAf0(0,1,0,1)),
        (HyperRectangle(Vec3f0(x), Vec3f0(baselen, baselen, dirlen)), RGBAf0(0,0,1,1))
    ]
    meshes = map(GLNormalMesh, rectangles)
    mesh(merge(meshes))

end
output(result)

```

## Moire

```julia
using Makie

result = let
    function cartesian(ll)
        return Point3f0(
            cos(ll[1]) * sin(ll[2]),
            sin(ll[1]) * sin(ll[2]),
            cos(ll[2])
        )
    end
    fract(x) = x - floor(x)
    function calcpositions(rings, index, time, audio)
        movement, radius, speed, spin = 1, 2, 3, 4;
        position = Point3f0(0.0)
        precision = 0.2f0
        for ring in rings
            position += ring[radius] * cartesian(
                precision *
                index *
                Point2f0(ring[spin] + Point2f0(sin(time * ring[speed]), cos(time * ring[speed])) * ring[movement])
            )
        end
        amplitude = audio[round(Int, clamp(fract(position[1] * 0.1), 0, 1) * (25000-1)) + 1]; # index * 0.002
        position *= 1.0 + amplitude * 0.5;
        position
    end
    rings = [(0.1f0, 1.0f0, 0.00001f0, Point2f0(0.2, 0.1)), (0.1f0, 0.0f0, 0.0002f0, Point2f0(0.052, 0.05))]
    N2 = 25000
    t_audio = sin.(linspace(0, 10pi, N2)) .+ (cos.(linspace(-3, 7pi, N2)) .* 0.6) .+ (rand(Float32, N2) .* 0.1) ./ 2f0
    start = time()
    t = (time() - start) * 100
    pos = calcpositions.((rings,), 1:N2, t, (t_audio,))

    scene = lines(pos, color = RGBAf0.(to_colormap(:RdBu, N2), 0.6), thickness = 0.6f0, show_axis = false)
    linesegments!(scene, FRect3D(Vec3f0(-1.5), Vec3f0(3)), raw = true, linewidth = 3, linestyle = :dot)
    eyepos = Vec3f0(5, 1.5, 0.5)
    lookat = Vec3f0(0)
    update_cam!(scene, eyepos, lookat)
    l = scene[1]
    N = 150
    record(scene, "/results/moire.gif", 1:N) do i
        t = (time() - start) * 700
        pos .= calcpositions.((rings,), 1:N2, t, (t_audio,))
        l[1] = pos # update argument 1
        rotate_cam!(scene, 0.0, 0.01, 0.01)
   end

end
output(result)

```

## Line GIF

```julia
using Makie

result = let
    us = linspace(0, 1, 100)
    scene = Scene()
    scene = linesegments!(scene, FRect3D(Vec3f0(0, -1, 0), Vec3f0(1, 2, 2)))
    p = lines!(scene, us, sin.(us .+ time()), zeros(100), linewidth = 3)[end]
    lineplots = [p]
    translate!(p, 0, 0, 0)
    colors = to_colormap(:RdYlBu)
    #display(scene) # would be needed without the record
    N = 150
    path = record(scene, "/results/line_gif.gif", 1:N) do i
        global lineplots, scene
        if length(lineplots) < 20
            p = lines!(
                scene,
                us, sin.(us .+ time()), zeros(100),
                color = colors[length(lineplots)],
                linewidth = 3
            )[end]
            unshift!(lineplots, p)
            translate!(p, 0, 0, 0)
            #TODO automatically insert new plots
            insert!(Makie.global_gl_screen(), scene, p)
        else
            lineplots = circshift(lineplots, 1)
            lp = first(lineplots)
            lp[2] = sin.(us .+ time())
            translate!(lp, 0, 0, 0)
        end
        for lp in Iterators.drop(lineplots, 1)
            z = translation(lp)[][3]
            translate!(lp, 0, 0, z + 0.1)
        end
    end
    path

end
output(result)

```

## Interaction with Mouse

```julia
using Makie

result = let
    scene = Scene()
    r = linspace(0, 3, 4)
    cam2d!(scene)
    time = Node(0.0)
    pos = lift(scene.events.mouseposition, time) do mpos, t
        map(linspace(0, 2pi, 60)) do i
            circle = Point2f0(sin(i), cos(i))
            mouse = to_world(scene, Point2f0(mpos))
            secondary = (sin((i * 10f0) + t) * 0.09) * normalize(circle)
            (secondary .+ circle) .+ mouse
        end
    end
    scene = lines!(scene, pos, raw = true)
    p1 = scene[end]
    p2 = scatter!(
        scene,
        pos, markersize = 0.1f0,
        marker = :star5,
        color = p1[:color],
        raw = true
    )[end]
    scene
    display(Makie.global_gl_screen(), scene)

    p1[:color] = RGBAf0(1, 0, 0, 0.1)
    p2[:marker] = 'π'
    p2[:markersize] = 0.2

    # push a reasonable mouse position in case this is executed as part
    # of the documentation
    push!(scene.events.mouseposition, (250.0, 250.0))
    N = 50
    record(scene, "/results/interaction_with_mouse.gif", linspace(0.01, 0.4, N)) do i
        push!(scene.events.mouseposition, (250.0, 250.0))
        p2[:markersize] = i
        push!(time, time[] + 0.1)
   end

end
output(result)

```

## Mouse Picking

```julia
using Makie

result = let
    img = rand(100, 100)
    scene = Scene()
    heatmap!(scene, img, scale_plot = false)
    clicks = Node(Point2f0[(0,0)])
    foreach(scene.events.mousebuttons) do buttons
       if ispressed(scene, Mouse.left)
           pos = to_world(scene, Point2f0(scene.events.mouseposition[]))
           push!(clicks, push!(clicks[], pos))
       end
       return
    end
    scatter!(scene, clicks, color = :red, marker = '+', markersize = 10, raw = true)

end
output(result)

```

## pong

```julia
using Makie

result = let
    xyvec = rand(Point2f0, (2)) .* 5 .+ 1
    velvec = rand(Point2f0, (2)) .* 10
    # define some other parameters
    t = 0
    ts = 0.03
    balldiameter = 1
    origin = Point2f0(0, 0)
    xybounds = Point2f0(10, 10)
    N = 200
    scene = scatter(
        xyvec,
        markersize = balldiameter,
        color = rand(RGBf0, 2),
        limits = FRect(0, 0, xybounds)
    )
    s = scene[end] # last plot in scene

    record(scene, "/results/pong.gif", 1:N) do i
        # calculate new ball position
        global t = t + ts
        global xyvec = xyvec .+ velvec .* ts
        global velvec = map(xyvec, xybounds, origin, velvec) do p, b, o, vel
            boolvec = ((p .+ balldiameter/2) .> b) .| ((p .- balldiameter/2) .< o)
            velvec = map(boolvec, vel) do b, v
                b ? -v : v
            end
        end
        # plot
        s[1] = xyvec
   end

end
output(result)

```

## pulsing marker

```julia
using Makie

result = let
    N = 100
    scene = scatter([0], [0], marker = '❤', markersize = 0.5, color = :red, raw = true)
    s = scene[end] # last plot in scene
    record(scene, "/results/pulsing_marker.gif", linspace(0, 10pi, N)) do i
        s[:markersize] = (cos(i) + 1) / (5 + 1)
   end

end
output(result)

```

## Travelling wave

```julia
using Makie

result = let
    scene = Scene()
    time = Node(0.0)
    f(v, t) = sin(v + t)
    scene = lines!(
        scene,
        lift(t -> f.(linspace(0, 2pi, 50), t), time),
        color = :blue
    )
    p1 = scene[end];
    N = 100
    record(scene, "/results/travelling_wave.gif", linspace(0, 4pi, N)) do i
        time[] = i
   end

end
output(result)

```

## Viridis scatter

```julia
using Makie

result = let
    N = 30
    scatter(1:N, 1:N, markersize = 2, color = to_colormap(:viridis, N))

end
output(result)

```

## Viridis meshscatter

```julia
using Makie

result = let
    N = 30
    R = 2
    theta = 4pi
    h = 5
    x = [R .* (t/3) .* cos(t) for t = linspace(0, theta, N)]
    y = [R .* (t/3) .* sin(t) for t = linspace(0, theta, N)]
    z = linspace(0, h, N)
    meshscatter(x, y, z, markersize = 0.5, color = to_colormap(:viridis, N))

end
output(result)

```

## Marker sizes + Marker colors

```julia
using Makie

result = let
    scatter(
        rand(20), rand(20),
        markersize = rand(20) ./20 + 0.02,
        color = rand(RGBf0, 20)
    )

end
output(result)

```

## Marker offset

```julia
using Makie

result = let
    scene = Scene(resolution = (500, 500))
    points = Point2f0[(0,0), (1,1), (2,2)]
    offset = rand(Point2f0, 3)./5
    scatter!(scene, points)
    scatter!(scene, points, marker_offset = offset, color = :red)

end
output(result)

```

## colormaps

```julia
using Makie

result = let
    h = 0.0
    offset = 0.1
    scene = Scene()
    cam2d!(scene)
    plot = map(AbstractPlotting.colorbrewer_names) do cmap
        global h
        c = to_colormap(cmap)
        cbar = image!(
            scene,
            linspace(0, 10, length(c)),
            linspace(0, 1, length(c)),
            reshape(c, (1, length(c))),
            show_axis = false
        )[end]
        text!(
            scene,
            string(cmap, ":"),
            position = Point2f0(-0.1, 0.5 + h),
            align = (:right, :center),
            show_axis = false,
            textsize = 0.4
        )
        translate!(cbar, 0, h, 0)
        h -= (1 + offset)
    end
    scene

end
output(result)

```

## Available markers

```julia
using Makie
 using GeometryTypes

result = let
    scene = Scene()
    marker = collect(AbstractPlotting._marker_map)
    positions = Point2f0.(0, 1:length(marker))
    scatter!(
        scene,
        positions,
        marker = last.(marker),
        markersize = 0.8,
        raw = true,
        marker_offset = Vec2f0(0.5, -0.4)
    )
    cam2d!(scene)
    annotations!(
        scene,
        string.(":", first.(marker)),
        positions,
        align = (:right, :center),
        textsize = 0.4,
        raw = true
    )

end
output(result)

```

## Theming

```julia
using Makie

result = let
    new_theme = Theme(
        resolution = (500, 500),
        linewidth = 3,
        colormap = :RdYlGn,
        color = :red,
        scatter = Theme(
            marker = '⊝',
            markersize = 0.03,
            strokecolor = :black,
            strokewidth = 0.1,
        ),
    )
    AbstractPlotting.set_theme!(new_theme)
    scene = scatter(rand(100), rand(100))
    st = Stepper(scene, "/results/theming")
    step!(st)
    new_theme[:color] = :blue
    step!(st)
    new_theme[:scatter, :marker] = '◍'
    step!(st)
    new_theme[:scatter, :markersize] = 0.05
    step!(st)
    new_theme[:scatter, :strokewidth] = 0.1
    step!(st)
    new_theme[:scatter, :strokecolor] = :green
    step!(st)
    empty!(scene)
    scene = scatter!(rand(100), rand(100))
    step!(st)
    scene[end][:marker] = 'π'
    step!(st)

    r = linspace(-0.5pi, pi + pi/4, 100)
    AbstractPlotting.set_theme!(new_theme)
    empty!(scene)
    scene = surface!(r, r, (x, y)-> sin(2x) + cos(2y))
    step!(st)
    scene[end][:colormap] = :PuOr
    step!(st)
    surface!(r + 2pi - pi/4, r, (x, y)-> sin(2x) + cos(2y))
    step!(st)
    AbstractPlotting.set_theme!(resolution = (500, 500))
    empty!(scene)
    surface!(r + 2pi - pi/4, r, (x, y)-> sin(2x) + cos(2y))
    step!(st)
    st

end
output(result)

```

## Axis theming

```julia
using Makie
 using GeometryTypes

result = let
    scene = Scene()
    points = decompose(Point2f0, Circle(Point2f0(10), 10f0), 9)
    lines!(
        scene,
        points,
        linewidth = 8,
        color = :black
    )

    axis = scene[Axis] # get axis
    scene

    st = Stepper(scene, "/results/axis_theming")
    step!(st)
    axis[:frame][:linewidth] = 5
    step!(st)
    axis[:grid][:linewidth] = (1, 5)
    step!(st)
    axis[:grid][:linecolor] = ((:red, 0.3), (:blue, 0.5))
    step!(st)
    axis[:names][:axisnames] = ("x", "y   ")
    step!(st)
    axis[:ticks][:title_gap] = 1
    step!(st)
    axis[:names][:rotation] = (0.0, -3/8*pi)
    step!(st)
    axis[:names][:textcolor] = ((:red, 1.0), (:blue, 1.0))
    step!(st)
    axis[:ticks][:font] = ("Dejavu Sans", "Helvetica")
    step!(st)
    axis[:ticks][:rotation] = (0.0, -pi/2)
    step!(st)
    axis[:ticks][:textsize] = (3, 7)
    step!(st)
    axis[:ticks][:gap] = 5
    step!(st)

end
output(result)

```

## Test

```julia
using Makie

result = let
    scene = text(
        "boundingbox", raw = true,
        align = (:left, :center),
        position = (200, 50)
    )
    campixel!(scene)
    linesegments!(boundingbox(scene), raw = true)

    offset = 0
    for a_lign in (:center, :left, :right), b_lign in (:center, :left, :right)
        t = text!(
            "boundingbox", raw = true,
            align = (a_lign, b_lign),
            position = (200, 100 + offset)
        )[end]
        linesegments!(boundingbox(t), raw = true)
        offset += 50
    end
    scene

end
output(result)

```

## Test

```julia
using Makie

result = let
   poly(IRect(0, 0, 200, 200), strokewidth=20, strokecolor=:red, color=(:black, 0.4))
end
output(result)

```

## Test

```julia
using Makie

result = let
    scene = poly([Rect(0, 0, 20, 20)])
    scatter!(Rect(0, 0, 20, 20), color = :red, markersize = 2, raw = true)

end
output(result)

```

## Test

```julia
using Makie

result = let
   scatter(rand(10), color=rand(10), colormap=:Spectral)
end
output(result)

```

## Test

```julia
using Makie

result = let
    lines(Rect(0, 0, 1, 1), linewidth = 4, scale_plot = false)
    scatter!([Point2f0(0.5, 0.5)], markersize = 1, marker = 'I', scale_plot = false)

end
output(result)

```

## Test

```julia
using Makie

result = let
   lines(rand(10), rand(10), color=rand(10), linewidth=10)
end
output(result)

```

## Test

```julia
using Makie

result = let
   lines(rand(10), rand(10), color=rand(RGBAf0, 10), linewidth=10)
end
output(result)

```

## Test

```julia
using Makie

result = let
   meshscatter(rand(10), rand(10), rand(10), color=rand(10))
end
output(result)

```

## Test

```julia
using Makie

result = let
   meshscatter(rand(10), rand(10), rand(10), color=rand(RGBAf0, 10))
end
output(result)

```

## Test

```julia
using Makie

result = let
    scene = Scene()
    cam2d!(scene)
    axis2d!(
        scene, IRect(Vec2f0(0), Vec2f0(1)),
        ticks = NT(
            ranges = ([0.1, 0.2, 0.9], [0.1, 0.2, 0.9]),
            labels = (["😸", "♡", "𝕴"], ["β ÷ δ", "22", "≙"])
        )
    )
    center!(scene)
    scene

end
output(result)

```

## Test

```julia
using Makie

result = let
    angles = linspace(0, 2pi, 20)
    pos = Point2f0.(sin.(angles), cos.(angles))
    scatter(pos, rotations = -angles , marker = '▲', scale_plot = false)
    scatter!(pos, markersize = 0.02, color = :red, scale_plot = false)

end
output(result)

```

## Type recipe for molecule simulation

```julia
using Makie
 import AbstractPlotting: Plot, default_theme, plot!, to_value
 using Makie

result = let

    struct Simulation
        grid::Vector{Point3f0}
    end
    # Probably worth having a macro for this!
    function default_theme(scene::SceneLike, ::Type{<: Plot(Simulation)})
        Theme(
            advance = 0,
            molecule_sizes = [0.08, 0.04, 0.04],
            molecule_colors = [:maroon, :deepskyblue2, :deepskyblue2]
        )
    end

    # The recipe! - will get called for plot(!)(x::SimulationResult)
    function AbstractPlotting.plot!(p::Plot(Simulation))
        sim = to_value(p[1]) # first argument is the SimulationResult
        # when advance changes, get new positions from the simulation
        mpos = lift(p[:advance]) do i
            sim.grid .+ rand(Point3f0, length(sim.grid)) .* 0.01f0
        end
        # size shouldn't change, so we might as well get the value instead of signal
        pos = to_value(mpos)
        N = length(pos)
        sizes = lift(p[:molecule_sizes]) do s
            repeat(s, outer = N ÷ 3)
        end
        sizes = lift(p[:molecule_sizes]) do s
            repeat(s, outer = N ÷ 3)
        end
        colors = lift(p[:molecule_colors]) do c
            repeat(c, outer = N ÷ 3)
        end
        scene = meshscatter!(p, mpos, markersize = sizes, color = colors)
        indices = Int[]
        for i in 1:3:N
            push!(indices, i, i + 1, i, i + 2)
        end
        meshplot = p.plots[end] # meshplot is the last plot we added to p
        # meshplot[1] -> the positions (first argument) converted to points, so
        # we don't do the conversion 2 times for linesegments!
        linesegments!(p, lift(x-> view(x, indices), meshplot[1]))
    end

    # To write out a video of the whole simulation
    n = 5
    grid = Point3f0.(linspace(-1, 1, n), reshape(linspace(-1, 1, n), (1, n, 1)), reshape(linspace(-1, 1, n), (1, 1, n)))
    molecules = map(1:(n^3) * 3) do i
        i3 = ((i - 1) ÷ 3) + 1
        xy = 0.1; z = 0.08
        i % 3 == 1 && return grid[i3]
        i % 3 == 2 && return grid[i3] + Point3f0(xy, xy, z)
        i % 3 == 0 && return grid[i3] + Point3f0(-xy, xy, z)
    end
    result = Simulation(molecules)
    scene = plot(result)
    N = 100
    record(scene, "/results/type_recipe_for_molecule_simulation.gif", 1:N) do i
        scene[end][:advance] = i
   end

end
output(result)

```
