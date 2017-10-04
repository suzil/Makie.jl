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
    "location": "labels.html#",
    "page": "Legend",
    "title": "Legend",
    "category": "page",
    "text": ""
},

{
    "location": "labels.html#Legend-1",
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

]}
