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
    "page": "-",
    "title": "-",
    "category": "page",
    "text": ""
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
    "page": "-",
    "title": "-",
    "category": "page",
    "text": ""
},

]}
