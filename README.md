# StanDump
[![Project Status: WIP - Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](http://www.repostatus.org/badges/latest/wip.svg)](http://www.repostatus.org/#wip)
[![Build Status](https://travis-ci.org/tpapp/StanDump.jl.svg?branch=master)](https://travis-ci.org/tpapp/StanDump.jl)
[![Coverage Status](https://coveralls.io/repos/tpapp/StanDump.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/tpapp/StanDump.jl?branch=master)
[![codecov.io](http://codecov.io/github/tpapp/StanDump.jl/coverage.svg?branch=master)](http://codecov.io/github/tpapp/StanDump.jl?branch=master)

Julia package for dumping data in a format that can be read by [CmdStan](http://mc-stan.org/interfaces/cmdstan.html).

# Example usage

```julia
data = Dict(:N => 200)
data[:x] = randn(data[:N])
open(io -> standump(io, data), "w")
```

# Key features

1. `standump(sd, xs...)` is the main entry point. The first argument is a `StanDumpIO` object, which wraps an `IO` stream, the other arguments are dumped into this in the format recognized by Stan.
2. Use the constructor of `StanDumpIO` to specify options, eg whether to use `=` or `<-` for assignment, to squash spaces, etc.
3. Dictionaries are written out as `variable = value` assignments. Symbols are used for variable names, with minimal validation. This is the most common use case, unless you wish to avoid constructing one (because your data is large).
4. `standump(::IO, ::Dict; options...)` is a convenient shorthand for the above case.
