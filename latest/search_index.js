var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "Home",
    "title": "Home",
    "category": "page",
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
    "page": "-",
    "title": "-",
    "category": "page",
    "text": ""
},

{
    "location": "labels.html#",
    "page": "-",
    "title": "-",
    "category": "page",
    "text": ""
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
    "page": "-",
    "title": "-",
    "category": "page",
    "text": ""
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
    "text": ""
},

]}
