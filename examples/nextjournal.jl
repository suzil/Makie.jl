using Makie

include("library.jl")
cd(@__DIR__)
function outputfile(entry, ending)
    ending = ending == ".mp4" ? ".gif" : ending
    "/results/" * string(entry.unique_name, ending)
end

open("makie_article.md", "w") do io
    println(io, raw"""
    # Makie examples

    ```Julia
    using Makie
    # work around the fact that nextjournal doesn't have display incorperated correctly
    output(x::String) = cp(x, \"/results/$(basename(x))\")
    output(x::Scene) = Makie.save(\"/results/test.png\", x)
    function output(x::Stepper)
        for file in readdir(x.path)
            cp(joinpath(x.path, file), \"/results/\")
        end
    end

    ```
    """)
    examples2source(scope_start = "result = let\n", scope_end = "end", indent = "   ", outputfile = outputfile) do entry, source
        println(io, "## ", entry.title)
        println(io, "\n```julia")
        println(io, source)
        println(io, "output(result)")
        println(io, "")
        println(io, "```\n")
    end
end
