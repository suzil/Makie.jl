var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "index.html#MakiE-1",
    "page": "Home",
    "title": "MakiE",
    "category": "section",
    "text": ""
},

{
    "location": "functions.html#",
    "page": "Functions",
    "title": "Functions",
    "category": "page",
    "text": ""
},

{
    "location": "functions.html#Functions-1",
    "page": "Functions",
    "title": "Functions",
    "category": "section",
    "text": "Primitive plotting functions. These are the most atomic operations from which one can stack together more complex plots\nscatter\nlines\nimage\nsurface\nvolume\ntext\npoly\nmesh\n "
},

{
    "location": "extending.html#",
    "page": "Extending MakiE",
    "title": "Extending MakiE",
    "category": "page",
    "text": ""
},

{
    "location": "extending.html#Extending-MakiE-1",
    "page": "Extending MakiE",
    "title": "Extending MakiE",
    "category": "section",
    "text": "There are 3 ways to extend MakiE:By creating a new function e.g. like scatter\nBy overloading plot(...) for your own type\nBy adding a new primitive + shader"
},

{
    "location": "extending.html#Option-1-1",
    "page": "Extending MakiE",
    "title": "Option 1",
    "category": "section",
    "text": "The first option is quite trivial and can be done in any plotting package and language: just create a function that scripts together a Plot."
},

{
    "location": "extending.html#Option-2-1",
    "page": "Extending MakiE",
    "title": "Option 2",
    "category": "section",
    "text": "Option 2 is very similar to Plots.jl recipes. Inside the function you can just use all of the plotting and drawing API to create a rich visual representation of your type. The signature that needs overloading is:function plot(obj::MyType, kw_args::Dict)\n    # use primitives and other recipes to create a new plot\n    scatter(obj, kw_arg[:my_attribute])\n    lines(...)\n    polygon(...)\nend"
},

{
    "location": "extending.html#Option-3-1",
    "page": "Extending MakiE",
    "title": "Option 3",
    "category": "section",
    "text": "Option 3 is pretty unique and is a real extension of MakiE's functionality as it adds a new primitive drawing type. This interface will likely change a lot in the future, since it carries quite a lot of technical debt from the design of GLAbstraction + GLVisualize, but this is how you can do it right now:You will need to create defaults for the attributes of your new visual. For a documentation on how to use this macro look at @default(func_expr).\nmy_attribute_convert(A::Array) = Texture(A)\nmy_attribute_convert(A::Texture) = A\nmy_attribute_convert(A) = error(\"A needs to be an array or Texture. Found: $(typeof(A))\")\n\n@default function my_drawing_type(scene, kw_args)\n    my_attribute = my_attribute_convert(my_attribute)\n    another_attribute = another_attribute::Float32 # always gets converted to Float32\nend\n\nfunction my_drawing_type(main_object::MyType, kw_args::Dict)\n    # optionally expand keyword arguments. E.g. m = (1, :white) becomes markersize = 1, markercolor = :white\n    kw_args = expand_kwargs(kw_args)\n    scene = get_global_scene()\n    kw_args = my_drawing_type(scene, kw_args) # fill in and convert attributes\n\n    boundingbox = Signal(AABB(Vec3f0(0), Vec3f0(1))) # calculate a boundingbox from your data\n\n    primitive = GL_TRIANGLES\n\n    vsh = vert\"\"\"\n        {{GLSL_VERSION}}\n        in vec2 position;\n        void main(){\n            gl_Position = vec4(position, 0, 1.0);\n        }\n    \"\"\"\n\n    fsh = frag\"\"\"\n        {{GLSL_VERSION}}\n        out vec4 outColor;\n        void main() {\n            outColor = vec4(1.0, 1.0, 1.0, 1.0);\n        }\n    \"\"\"\n    program = LazyShader(vsh, fsh)\n    robj = std_renderobject(shader_uniforms, program, boundingbox, primitive, nothing)\n    # The attributes that you add to the scene should be all signals and all editable.\n    # if an attribute is fixed, don't add it to the scene\n    insert_scene!(scene, :scatter, viz, attributes)\n    attributes\nend\n"
},

{
    "location": "referencing.html#",
    "page": "Referencing",
    "title": "Referencing",
    "category": "page",
    "text": ""
},

{
    "location": "referencing.html#Referencing-1",
    "page": "Referencing",
    "title": "Referencing",
    "category": "section",
    "text": "MakiE offers a sophisticated referencing system to share attributes across the Scene in your plot. This is great for animations and saving resources - also if the backend decides to put data on the GPU you might even share those in GPU memory.This allows the following use cases:"
},

{
    "location": "referencing.html#@ref-1",
    "page": "Referencing",
    "title": "@ref",
    "category": "section",
    "text": "@ref Variable = Value # Inserts Value under name Variable into Scene@ref Scene.Name1.Name2 # Syntactic sugar for Scene[:Name1, :Name2] @ref Expr1, Expr1 # Syntactic sugar for (@ref Expr1, @ref Expr2)"
},

{
    "location": "referencing.html#Using-Mouse-and-Time-to-animate-plots-1",
    "page": "Referencing",
    "title": "Using Mouse and Time to animate plots",
    "category": "section",
    "text": "using MakiE\n\nscene = Scene()\n\nscatter(map((mpos, t)-> mpos .+ (sin(t), cos(t)), @ref Scene.Mouse, Scene.Time))\n"
},

{
    "location": "referencing.html#Animating-and-sharing-on-the-GPU-1",
    "page": "Referencing",
    "title": "Animating and sharing on the GPU",
    "category": "section",
    "text": "using MakiE\n\nscene = Scene()\n@ref A = rand(32, 32) # if uploaded to the GPU, it will be shared on the GPU\n\nsurface(@ref A) # refer to exactly the same a in wireframe and surface plot\nwireframe((@ref A) .+ 0.5) # offsets A on the GPU based on the same data\n\nfor i = 1:10\n    # updates A - resulting in an animation of the surface and offsetted wireframe plot\n    @ref A[:, :] = rand(32, 32)\nend"
},

{
    "location": "referencing.html#Simple-GUI-1",
    "page": "Referencing",
    "title": "Simple GUI",
    "category": "section",
    "text": "using MakiE\n\nscene = Scene()\n@ref slicer1 = slider(linspace(0, 1, 100)) # create a slider\n\n# generate some pretty data\nfunction xy_data(x,y,i)\n    x = (x - 0.5f0) * i\n    y = (y - 0.5f0) * i\n    r = sqrt(x * x + y * y)\n    Float32(sin(r) / r)\nend\n\nsurf(i, N) = Float32[xy_data(x, y, i, N) for x = linspace(0, 1, N), y = linspace(0, 1, N)]\n\nsurface(surf.(@ref slicer1, 512)) # refer to exactly the same a in wireframe and surface plot\n"
},

{
    "location": "axis.html#",
    "page": "Axis",
    "title": "Axis",
    "category": "page",
    "text": ""
},

{
    "location": "axis.html#Axis-1",
    "page": "Axis",
    "title": "Axis",
    "category": "section",
    "text": "The axis is just a scene object, making it easy to manipulate and share between plots. Axis objects also contains the mapping you want to apply to the data and can interactively be changed. An Axis object can be created from any boundingbox and inserted into any plot."
},

{
    "location": "legends.html#",
    "page": "Legend",
    "title": "Legend",
    "category": "page",
    "text": ""
},

{
    "location": "legends.html#Legend-1",
    "page": "Legend",
    "title": "Legend",
    "category": "section",
    "text": "The Legend is an interactive object, that can be edited and interacted with like any other object in MakiE.You can create it on your own, or let it get created by automatically by a plot command.\nscene = Scene()\n\nlegend = Legend(\n    names = [\"hello\", \"names\"],\n    markers = [:circle, :plus],\n    colors = [:white, :black],\n    backgroundcolor = :gray\n)\n\nlegend[:names][1] = \"update name\" # easily update the names in the label\n\nlegend[:colors] = [:green, :blue] # update color and all other attributes in the same way\n\n# add to a plot\n\np = plot(rand(10, 2))\n\np[:legend] = legend # voila, your plot now has a legend.\n\n# Alternatively do:\n\np = plot(rand(10, 2), legend = Legend(names = [\"hello\", \"legend\"]))"
},

{
    "location": "output.html#",
    "page": "Input Output",
    "title": "Input Output",
    "category": "page",
    "text": ""
},

{
    "location": "output.html#Input-Output-1",
    "page": "Input Output",
    "title": "Input Output",
    "category": "section",
    "text": "MakiE overloads the FileIO interface. So you can just write e.g.:save(scene, \"test.png\")\nsave(scene, \"test.jpg\")There is also the option to save a plot as a Julia File:save(scene, \"test.jl\")This will try to reproduce the plotting commands as closely as possible to recreate the current scene. You can specify if you want to save the defaults explicitly or if you not want to store them, so that whenever you change defaults and the saved code gets loaded it will take the new defaults."
},

{
    "location": "reflection.html#",
    "page": "Reflection",
    "title": "Reflection",
    "category": "page",
    "text": ""
},

{
    "location": "reflection.html#Reflection-1",
    "page": "Reflection",
    "title": "Reflection",
    "category": "section",
    "text": "Since objects with links (as explained in Referencing) to each other, all animatable etc, a plot object can become fairly complex. To work against this, there is a rich reflection api, allowing you to look into the scene tree, display what objects are linked and interactively change the attributes."
},

{
    "location": "layout.html#",
    "page": "Layouting",
    "title": "Layouting",
    "category": "page",
    "text": ""
},

{
    "location": "layout.html#Layouting-1",
    "page": "Layouting",
    "title": "Layouting",
    "category": "section",
    "text": "Every object contains a boundingbox and a box indicating where the object should be placed. By default, those boxes are the same. But if you want to move, stretch, scale an object, you can edit the latter. This can be a manual process, or an automatic one. E.g. there are several functions which try to automatically find a layout for certain objects."
},

{
    "location": "layout.html#Automatic-interface-1",
    "page": "Layouting",
    "title": "Automatic interface",
    "category": "section",
    "text": "layout!(object1, object2, objectN...) 1D grid (alternatively use a vector)\nlayout!(Matrix{Objects}(...)) # 2d Grid\nlayout!(Array{Objects, 3}(...))\n\n# TODO port layouting options from Plots.jl\n"
},

{
    "location": "layout.html#Manual-interface-1",
    "page": "Layouting",
    "title": "Manual interface",
    "category": "section",
    "text": "\nscale!(object, 1f0) # ND version with same scalar for all dimensions\nscale!(object, (1f0, 2f0)) # 2d\nscale!(object, (1f0, 2f0, 3f0)) # 3d\n\nrotate!(object, axis::Vec, amount_degree)\n\nmove!(object, amount) # for amount it's the same as with scale!\n\n# boundingbox can be any rect type, e.g. a 3D or 2D HyperRectangle\n# with the effect of exactly fitting `object` into `boundingbox`\nmove!(object, boundingbox)"
},

{
    "location": "devdocs.html#",
    "page": "-",
    "title": "-",
    "category": "page",
    "text": ""
},

]}
