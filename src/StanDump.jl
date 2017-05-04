module StanDump

export StanDumpIO, standump

"""
Wrapper for an IO stream for writing data for use by Stan. See
constructor for documentation of slots.
"""
struct StanDumpIO
    io::IO
    def_arrow::Bool
    def_newline::Bool
    compact::Bool
end

"""
    StanDumpIO(io; def_arrow = false, def_newline = false, compact = false)

Wrap an IO stream `io` for writing data to be read by Stan.

# Arguments
* `def_arrow::Bool`: when `true` use `<-`, otherwise `=` for variable definitions.
* `def_newline::Bool`: when `true`, `=` or `<-` is followed by a newline.
* `compact::Bool`: when `true`, drop spaces when possible.
"""
function StanDumpIO(io; def_arrow = false, def_newline = false, compact = false)
    StanDumpIO(io, def_arrow, def_newline, compact)
end

"""
    standump(sd, xs...)

Write arguments `xs...` as data for Stan into `sd`.

Methods are only provided for objects which are valid. Use `varname =>
value` (`Pair`) to represent assignments.
"""
standump(sd::StanDumpIO, xs...) = for x in xs standump(sd, x) end

standump(sd::StanDumpIO, x) = error("Can't represent $x as data for Stan.")

"""
    _standump(sd, xs...)

Write arguments `xs...` as data for Stan into `sd`, passing through
strings and characters, and allowing other special objects which are
not valid data.

NOTE: For internal use. Define `standump` methods for valid Stan
objects, and `_standump` methods for everything else, which are called
by the former.
"""
_standump(sd::StanDumpIO, xs...) = for x in xs _standump(sd, x) end

_standump(sd::StanDumpIO, x) = standump(sd, x)

_standump(sd::StanDumpIO, x::Union{Char,String}) = print(sd.io, x)

"Write a space unless output is requested to be compact."
struct CompactSpace end
const COMPACTSPACE = CompactSpace()

_standump(sd::StanDumpIO, ::CompactSpace) = if !sd.compact print(sd.io, " ") end

function standump(sd::StanDumpIO, x::Integer)
    if typemin(Int32) ≤ x ≤ typemax(Int32)
        print(sd.io, x)
    elseif typemin(Int64) ≤ x ≤ typemax(Int64)
        print(sd.io, x, "L")
    else
        error("Integer too large to represent in Stan.")
    end
end
        
standump(sd::StanDumpIO, x::Real) = print(sd.io, Float64(x))

"""
    is_valid_stan_varname(varname)

Test if `varname` is valid as a Stan variable name.

NOTE: only basic checks, does not test conflicts with reserved names.
"""
function is_valid_stan_varname(varname::String)
    isvalid(c) = isascii(c) && (isalnum(c) || c == '_')
    all(isvalid, varname) && isalpha(varname[1]) &&
        (varname[max(1,end-1):end] != "__")
end

function _standump(sd::StanDumpIO, x::Symbol)
    v = string(x)
    @assert is_valid_stan_varname(v) "Invalid variable name $v."
    print(sd.io, v)
end

function standump{T}(sd::StanDumpIO, x::Pair{Symbol,T})
    _standump(sd,
              x.first, COMPACTSPACE,
              sd.def_arrow ? "<-" : '=',
              sd.def_newline ? "\n" : COMPACTSPACE,
              x.second, "\n")
end

function _standump_vector{T <: Real}(sd::StanDumpIO, xs::AbstractVector{T})
    if isempty(xs)
        _standump(sd, T <: Integer ? "integer" : "double", "(0)")
    else
        _standump(sd, "c(")
        for (i,x) in enumerate(xs)
            if i > 1
                _standump(sd, ",", COMPACTSPACE)
            end
            _standump(sd, x)
        end
        _standump(sd, ")")
    end
end

standump{T <: Real}(sd::StanDumpIO, xs::AbstractVector{T}) =
    _standump_vector(sd, xs)

function standump{T <: Integer}(sd::StanDumpIO, r::UnitRange{T})
    if r.start <= r.stop
        _standump(sd, r.start, ":", r.stop)
    else
        _standump_vector(sd, r)
    end
end

function standump{T <: Real}(sd::StanDumpIO, A::AbstractArray{T})
    _standump(sd, "structure(", view(A, :), ",", COMPACTSPACE,
              ".Dim", COMPACTSPACE, "=", COMPACTSPACE, collect(size(A)), ")")
end

end # module
