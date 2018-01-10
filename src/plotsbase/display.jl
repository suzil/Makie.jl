const current_backend = Ref(:makie)


"""

scatter(args...; kwargs...) = plot(Scene{Scatter}(kw_args), args...)

root = plot() # returns rootscene
# root contains a theme, from which all defaults get feeded
# root also contains all window signals

root = plot(root, rand(10), thickness = 1mm) # creates a new node, inheriting from root
root = plot(rand(10), thickness = 1mm) # equal to the above
# -root
#     -p1
 # adds a new node to p1, inheriting attributes from p1
p1 = plot!(p1, rand(10)) # takes defaults from theme
# root
    # p1
        # p2
root = plot!(root, rand(10), p1, color = :red) # takes defaults from kw_args, then p1, then root.theme
# root
    # p1
        # p2
    # p3

# convenient way to access subplots
root[1] == p1
p1[1] == p2 && p2 == root[1][1]
root[2] == p3

pcombined = plot(root...) # equals to plot(root[1], root[2]) # equals to plot(p1, p3)
# pcombined
    # subplot1
        # p1
            # P2
    # subplot2
        # p3
#=
┏━━━━━━━┳━━━━━┓
┃ p1 p2 ┃ p3  ┃
┗━━━━━━━┻━━━━━┛
=#
pcombined == hbox(root...) # horizontal concat layout
pcombined == vbox(root...) # vertical concat layout

p2 = pop!(root[1]) # delete the last plot from (root[1] == p1)
layouted = vbox(hbox(root[1], p2), root[2]) # vertical + horizontal layout combined
# pcombined
    # subplot1 vertical
        # subplot 2 horizontal
            # p1
        # subplot 3 horizontal
            # p2
    # subplot2 vertical
        # p3
#=
┏━━━━┳━━━━┓
┃ p1 ┃ p2 ┃
┣━━━━┻━━━━┫
┃   p3    ┃
┗━━━━━━━━━┛
=#

p1 = root[1]
p3 = root[2]
layouted_axis = vbox(hbox(p1, plot(p2, axis = p2[:axis]), p3)) # vertical + horizontal layout combined

#=
┏━━━━┳━━━━┓
┃ p1 ┃ p2 ┃ # p1, p2 share the same axis object
┣━━━━┻━━━━┫
┃   p3    ┃
┗━━━━━━━━━┛
=#

# the above will all be backend independent!
display(layouted) # create the actual plot + window for the preferred + backend / display combo

disp = gl_display(resolution = ...) # explicitely chose a gl backend for display
display(disp, layouted)
"""
struct MDisplay{T} <: Base.Display
    area::NTuple{4, Float64}
    parent::Nullable{MDisplay{T}}
    children::Vector{MDisplay{T}}
    rendercontext::T
    # rootscene::Scene
end
function traverse(x, y)
    # error("Lol")
end
function Base.display(x::MDisplay, y)
    println("hehe")
    traverse(x, y)
    show(y)
end
disp = MDisplay((1.0,1.0,1.0,1.0), Nullable{MDisplay}(), MDisplay[], nothing)
pushdisplay(disp)
using Media
struct Lol end
# media(Lol, Media.Graphical)
setdisplay(Lol, disp)
function Media.render(x::MDisplay, y)
    println("hehe")
    traverse(x, y)
    show(y)
end
