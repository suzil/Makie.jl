using MeshCat
using CoordinateTransformations
import GeometryTypes: HyperRectangle, Vec, Point, HomogenousMesh, SignedDistanceField
import ColorTypes: RGBA, RGB
# Create a new visualizer instance
vis = Visualizer()
open(vis)

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
cd(@__DIR__)
using FixedPointNumbers, Colors
logo = joinpath(@__DIR__, "..", "docs", "src", "assets", "logo.png")
x = FileIO.load(logo)
FileIO.save("logo2.png", RGB{N0f8}.(x))
logo = joinpath("logo2.png")

x = MeshCat.CustomMaterial(
    vertexShader = String(open(read, "particles.vert")),
    fragmentShader = String(open(read, "particles.frag")),
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
