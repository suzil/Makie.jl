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
    ENV[\"DISPLAY\"] = \":0\"
    using Makie
    output(x::String) = nothing
    output(x::Scene) = Makie.save(\"/results/test.png\", x)
    output(x::Stepper) = nothing
    ```
    """)
    examples2source(exclude_tags = ["test"], scope_start = "result = let\n", scope_end = "end", indent = "   ", outputfile = outputfile) do entry, source
        println(io, "## ", entry.title)
        println(io, "\n```julia")
        println(io, source)
        println(io, "output(result)")
        println(io, "")
        println(io, "```\n")
    end
end
