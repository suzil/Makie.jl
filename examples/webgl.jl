using MeshCat
using CoordinateTransformations
import GeometryTypes: HyperRectangle, Vec, Point, HomogenousMesh, SignedDistanceField
import ColorTypes: RGBA, RGB
using MeshCat, Colors, GeometryTypes, CoordinateTransformations
using Parameters: @with_kw
using FixedPointNumbers, Colors

@with_kw mutable struct CustomMaterial <: MeshCat.AbstractMaterial
    _type::String = "ShaderMaterial"
    color::RGBA{Float32} = RGB(1., 1., 1.)
    map::Union{Texture, Void} = nothing
    depthFunc::Int = 3
    depthTest::Bool = true
    depthWrite::Bool = true
    vertexColors::Int = 0    # TODO: make an enum
    side::Int = 2            # TODO: make an enum https://github.com/mrdoob/three.js/blob/d55897b8e9b2632896d8ac146a05b3b4be3668f8/src/constants.js#L14
    fragmentShader::String
    vertexShader::String
end

function MeshCat.lower(material::CustomMaterial)
    data = Dict{String, Any}(
        "uuid" => string(MeshCat.uuid1()),
        "type" => "ShaderMaterial",
        "depthFunc" => material.depthFunc,
        "depthTest" => material.depthTest,
        "depthWrite" => material.depthWrite,
        "side" => material.side,
        "vertexColors" => material.vertexColors,
        "fragmentShader" => material.fragmentShader,
        "vertexShader" => material.vertexShader,
    )
    if material.map !== nothing
        data["uniforms"] = Dict(
            "loli" => Dict(
                "type" => "t",
                "value" => MeshCat.lower(material.map)
            )
        )
    end
    data
end

# Create a new visualizer instance
vis = Visualizer()
open(vis)

cd(@__DIR__)
logo = joinpath(@__DIR__, "..", "docs", "src", "assets", "logo.png")

x = CustomMaterial(
    vertexShader = read("particles.vert", String),
    fragmentShader = read("particles.frag", String),
    map = Texture(image = PngImage(logo))
)

using GeometryTypes
setobject!(vis[:mesh], GLNormalUVMesh(SimpleRectangle(0, 0, 2, 2)), x)

viewer.scene_tree.find(["meshcat", "mesh", "<object>"]).object

using Makie

AbstractPlotting.reasonable_resolution()
scene = lines(Rect(0, 0, 200, 200))
display(scene)
screen = Makie.global_gl_screen();
window = screen.glscreen;
@show screen.framebuffer.resolution[]

using Images
screen.framebuffer.depth |> Makie.GLAbstraction.gpu_data .|> Gray
screen.framebuffer.color_luma |> Makie.GLAbstraction.gpu_data


using FileIO
using GeometryTypes: GLUVMesh # we need a mesh type that stores texture coordinates
image = PngImage(joinpath(MeshCat.VIEWER_ROOT, "..", "data", "HeadTextureMultisense.png"))
texture = Texture(image=image)
material = MeshCat.CustomMaterial(
    map = texture,
    vertexShader = String(open(read, "particles.vert")),
    fragmentShader = String(open(read, "particles.frag"))
)
# geometry = load(joinpath(MeshCat.VIEWER_ROOT, "..", "data", "head_multisense.obj"), GLUVMesh)
setobject!(vis[:mesh], GLNormalUVMesh(SimpleRectangle(0, 0, 2, 2)), material)
settransform!(vis["robots", "valkyrie"], Translation(0.5, -0.5, 0.5))

using Makie
scene = mesh(Makie.loadasset("cat.obj"));
scene[Axis][:frame, :linecolor] = ((:gray, 0.5), (:gray, 0.5), (:gray, 0.5))

function Base.insert!(vis::Visualizer, scene::Scene, x::Makie.Mesh)
    @get_attribute x (color,)
    setobject!(vis[:mesh], x[1][], MeshPhongMaterial(color = color))
end

function Base.insert!(vis::Visualizer, scene::Scene, x::Makie.LineSegments)
    @get_attribute x (color, linewidth)
    geometry = PointCloud(x[1][], color)
    setobject!(vis[:lines], MeshCat.LineSegments(geometry, LineBasicMaterial(vertexColors = 2)))
end



insert!(vis, scene, scene[end])
insert!(vis, scene, scene[1].plots[2])
scene
