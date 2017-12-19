using MacroTools, Reactive

"""
To cut down on anonymous functions, let's create an explicit
closure to pass the current scene to the convert function
"""
struct ConvertFun{F, Backend}
    func::F
    scene::Scene{Backend}
end

(CF::ConvertFun)(value) = CF.func(CF.scene, value)


function haskeys(kw_args::Void, keys...)
    return false
end

function haskeys(kw_args::Scene, keys...)
    all(key-> haskey(kw_args, key), keys)
end

#=

Default functions that are getting called when filling out the defaults for a scene

They are dispatched with scene::Scene, attributes::Scene
=#

function linked(scene::Scene, attributes::Scene, convert_func, keys)
    attribute = last(keys)
    node = get(attributes, attribute) do
        # first look up in full path
        get(scene, keys...) do
            get(scene, :theme, attribute) do
                root = rootscene(scene) # theme is in root!
                get(root, keys...) do
                    # then we look if there is a shared default
                    get(root, :theme, attribute) do
                        error("
                            Can't find a default for attribute $attribute with parent $(keys[1:end-1]).
                            This is either a bug or you deleted the default for $attribute from the theme.
                        ")
                    end
                end
            end
        end
    end

    return attributes.data[attribute] = lift_node(getcanvas(scene, false), node; convert = ConvertFun(convert_func, scene)) do canvas, value
        convert_func(scene, value)
    end
end

"""
Default generation for non optional attributes.
`attribute` needs to be in `attributes` and will get reinserted with the correct
conversion function and turned into a `Node`
Usage within the [`@defaults`](@ref) macro:
    ```example
    @defaultss scatter = begin
        user_attribute = to_attribute(user_attribute)
        # the above will desugar into
        c = default(scene, attributes, :scatter, :user_attribute, to_attribute)
        # which will boil down to these calls:
        to_attribute = to_node(attributes[:user_attribute], to_attribute)
    end
    ```
"""
function default(
        scene::Scene, attributes::Scene,
        keys::NTuple{N, Symbol},
        convert_func
    ) where N

    attribute = last(keys)
    node = get(attributes, attribute) do
        error("
            $attribute doesn't have a default, so it isn't optional. Please supply it!
            you will find more information what value it accepts in [`$(Symbol(convert_func))`](@ref) and
            possibly in the documentation of [`$(first(keys))`](@ref).
        ")
    end
    return attributes.data[attribute] = lift_node(getcanvas(scene, false), node; convert = ConvertFun(convert_func, scene)) do canvas, value
        convert_func(scene, value)
    end
end

"""
Default generation for an attribute with a default in the theme.
`attribute` doesn't need to be in `attributes` since it can be looked up in the current theme.
The final value will get taken from `attributes` or the scenes theme, and will get inserted into
`attributes` with the correct conversion function as a `Node`.
Usage in [`@defaults`](@ref) macro:
    ```example
    @defaultss scatter = begin
        a = to_a(0.0)
        # the above will desugar into
        c = default(scene, attributes, :scatter, :a, to_a, 0.0)
        # which will boil down to these calls:
        _c = get(attributes, :c, get(scene, (:theme, :c), get(scene, :c, error())))
        c = to_node(_c, to_a) # node with to_a as a convert func
    end
    ```
"""
function default(
        scene::Scene, attributes::Scene,
        keys::NTuple{N, Symbol},
        convert_func, val
    ) where N
    # First look in attributes, use last key,
    # since that's the attributes name and attributes has no hierarchy
    attribute = last(keys)
    node = get(attributes, attribute) do
        root = rootscene(scene) # theme is in root!
        # first look up in full path
        get(root, :theme, keys...) do
            # then we look if there is a shared default
            get(root, :theme, attribute) do
                error("
                    Can't find a default for attribute $attribute with parent $(keys[1:end-1]).
                    This is either a bug or you deleted the default for $attribute from the theme.
                ")
            end
        end
    end
    return attributes.data[attribute] = lift_node(getcanvas(scene, false), node; convert = ConvertFun(convert_func, scene)) do canvas, value
        convert_func(scene, value)
    end
end

"""
Calculated scene node, which relies on other nodes to calculate it's value!
It can still be overwritten by user supplied key word arguments.
Insert into node like this:
    ```example
    @defaultss scatter = begin
        a = to_a(0.0)
        b = to_b(0.0)
        c = calculate_func(a, b)
        # the above will desugar into
        c = calculated(scene, attributes, :scatter, :c, calculate_func, a, b)
        # which will boil down to these calls:
        c = get(attributes, :c, lift_node(calculate_func, a, b))
    end
    ```
"""
function calculated(scene::Scene, attributes::Scene, keys::NTuple{N, Symbol}, convert_func, args...) where N
    # Attribute overwritten by user, no need to calculate it!
    attribute = last(keys)
    node = if haskey(attributes, attribute)
        lift_node(getcanvas(scene, false), attributes[attribute]; convert = ConvertFun(convert_func, scene)) do canvas, val
            convert_func(scene, val)
        end
    else
        # we need to calculate it from args - by conention, first arg is always the scene
        lift_node(getcanvas(scene, false), args...; convert = ConvertFun(convert_func, scene)) do canvas, args...
            convert_func(scene, args...)
        end
    end
    attributes[attribute] = node
end


#=

Default functions that are getting called when filling in the theme values

They are dispatched with scene::Scene, attributes::Void <- since we don't have any attributes to fill
=#

"""
Variant (with `attributes == nothing`) inserting a default for `attribute` into the current theme
"""
function default(
        scene::Scene, attributes::Void,
        keys::NTuple{N, Symbol},
        convert_func, default_value
    ) where N
    scene[:theme, keys...] = to_node(default_value, identity, Any)
    default_value
end
# If no default value is given, we don't need to insert anything into the theme
default(scene::Scene, attributes::Void, keys::NTuple{N, Symbol}, convert_func) where N = nothing
linked(scene::Scene, attributes::Void, convert_func, keys) = nothing
calculated(scene::Scene, attributes::Void, keys, convert_func, args...) = nothing

#=

Default functions that are getting called when putting together the docs for an attribute

They are dispatched with docs::Dict, attributes::Void <- since we don't have any attributes to fill
with the docs::Dict getting filled with a docstring for each attribute
=#

"""
Generate attribute docs pushing them into `scene`
"""
function default(
        docs::Dict, attributes::Void,
        keys::NTuple{N, Symbol},
        convert_func, default_value = nothing # we don't care if there is no value
    ) where N
    func = Symbol(convert_func)
    docs[last(keys)] = "Attribute `$(last(keys))`, conversion function [`$func`](@ref)"
    default_value
end

"""
Insert docs into `scene` Dict for the calculated attribute
"""
function calculated(docs::Dict, attributes::Void, keys, convert_func, args...)
    func = Symbol(convert_func)
    docs[last(keys)] = "Calculated attribute `$(last(keys))`, with function [`$func`](@ref)"
end
function linked(docs::Dict, attributes::Void, convert_func, keys)
    func = Symbol(convert_func)
    docs[last(keys)] = "Linked attribute from `$(join(keys, "."))`, with function [`$func`](@ref)"
end


function process_call(scene, attributes, keys, func, args)
    # calculated attributes are ambigous with normal defaults, so we prefix it with calculate
    key_tuple = Expr(:tuple, keys...)
    if @capture(func, calculated.f_)
        return Expr(:call, calculated, esc(scene), esc(attributes), key_tuple, esc(f), esc.(args)...)
    end
    if length(args) == 1
        arg = args[1]
        expr = Expr(:call, default, esc(scene), esc(attributes), key_tuple, esc(func))
        if arg == last(keys).value
            # non optional attribute, doesn't have a default value
            return expr
        elseif @capture(arg, ssym_.children_) # reference to scene
            fields = extract_fields(arg)
            # we don't need to insert this node into the theme pass, since it get's
            # the value already from the scene. Instead of having yet another overload
            # of default, we just manually exclude it:
            return Expr(:call, linked, esc(scene), esc(attributes), esc(func), Expr(:tuple, fields...))
        else # attribute with default value
            push!(expr.args, esc(arg))
            return expr
        end
    end
    error("""
    Not a well formed default expr. Please use either of these:
    ```
        a = convert_func(default) # only use one argument - needs default value
        a = convert_func(scene.theme.attribute) # refer to values in the scene as default. Should usually refer to theme, but doesn't need to!
        a = convert_func(a) # doesn't need a default, symbols need match
        a = calculated.convert_func(...) # calculated something from other attributes. Arguments can be any node
    ```
    Found the following arguments:
    Attributes: $attributes, keys: $keys, function: $func, arguments: $(args)
    """)
end

function process_attribute(scene, attributes, parents, attribute, func, args)
    keys = (parents..., QuoteNode(attribute))
    call = process_call(scene, attributes, keys, func, args)
    :($(esc(attribute)) = $call)
end


process_block(scene, attributes, parents, block::Expr) = process_block(scene, attributes, parents, block.args)
function process_block(scene, attributes, parents, block::Vector)
    result = []
    for elem in block
        expr = esc(elem)
        if isa(elem, Expr)
            # we only process `a = func(args...)` and if/else/elseif blocks
            # leave rest untouched
            if @capture(elem, attribute_ = func_(args__))
                if isa(attribute, Symbol)
                    # only process symbol = ...
                    expr = process_attribute(scene, attributes, parents, attribute, func, args)
                else
                    expr = esc(elem)
                end
            elseif elem.head == :if
                cond = esc(elem.args[1])
                ifblock = Expr(:block, process_block(scene, attributes, parents, elem.args[2])...)

                elseblock = if length(elem.args) == 3
                    (Expr(:block, process_block(scene, attributes, parents, elem.args[3])...),)
                else
                    ()
                end
                expr = Expr(:if, cond, ifblock, elseblock...)
            end
        end
        push!(result, expr)
    end
    result
end

function _extract_fields(expr, fields = Symbol[])
    if isa(expr, Symbol)
        push!(fields, expr)
    elseif isa(expr, QuoteNode)
        _extract_fields(expr.value, fields)
    elseif @capture(expr, a_.b_)
        _extract_fields(a, fields)
        _extract_fields(b, fields)
    else
        error("Not a getfield expr: $expr, $(typeof(expr)) $(expr.head)")
    end
    return fields
end

extract_fields(expr) = QuoteNode.(_extract_fields(expr))


"""
@defaultss scene.name = begin
    ...
end
"""
macro defaults(assignment)
    @capture(assignment,
        attributes_ -> parents_ = block_
    ) || error("Please use `@defaults scene.name = begin ... end`")
    if isa(block, Expr) && block.head == :block
        parent_keys = extract_fields(parents)
        scene, keys = first(parent_keys).value, parent_keys[2:end] # should always be scene.[parent.child.etc]
        expr = Expr(:block, process_block(scene, attributes, keys, block)...)
        expr
    else
        error("Please use `@defaults scene.name = begin ... end`")
    end
end

nice_dump(x, intent = 0) = (print("    "^intent); show(x); println())
function nice_dump(x::Expr, intent = 0)
    Base.is_linenumber(x) && return
    println("    "^intent, "head: ", x.head)
    intent += 1
    for elem in x.args
        nice_dump(elem, intent)
    end
end
