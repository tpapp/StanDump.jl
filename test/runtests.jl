using StanDump
using Base.Test

function stanrepr(x; options...)
    sd = StanDumpIO( IOBuffer(); options...)
    standump(sd, x)
    String(take!(sd.io))
end

@testset "integer" begin
    @test stanrepr(1) == "1"
    @test stanrepr(typemax(Int32)+1) == string(typemax(Int32)+1) * "L"
    @test stanrepr(-99) == "-99"
    @test_throws ErrorException stanrepr(BigInt(typemax(Int64))+1)
end

@testset "float" begin
    @test stanrepr(1/7) == string(1/7)
    @test stanrepr(-pi) == string(Float64(-pi))
    @test stanrepr(Inf) == "Inf"
    @test stanrepr(-Inf) == "-Inf"
    @test stanrepr(Inf32) == "Inf"
    @test stanrepr(-Inf32) == "-Inf"
    @test stanrepr(NaN) == "NaN"
    @test stanrepr(1//2) == "0.5"
end

@testset "definition" begin
    @test stanrepr(:A => 99) == "A = 99\n" # defaults
    # non-compact
    @test stanrepr(:A => 99, def_arrow = false, def_newline = false,
                   compact = false) == "A = 99\n" # same as above
    @test stanrepr(:A => 99, def_arrow = true, def_newline = false,
                   compact = false) == "A <- 99\n"
    @test stanrepr(:A => 99, def_arrow = false, def_newline = true,
                   compact = false) == "A =\n99\n"
    @test stanrepr(:A => 99, def_arrow = true, def_newline = true,
                   compact = false) == "A <-\n99\n"
    # compact
    @test stanrepr(:A => 99, def_arrow = false, def_newline = false,
                   compact = true) == "A=99\n"
    @test stanrepr(:A => 99, def_arrow = true, def_newline = false,
                   compact = true) == "A<-99\n"
    @test stanrepr(:A => 99, def_arrow = false, def_newline = true,
                   compact = true) == "A=\n99\n" # same as above
    @test stanrepr(:A => 99, def_arrow = true, def_newline = true,
                   compact = true) == "A<-\n99\n"
end

@testset "vector" begin
    @test stanrepr([1,2]) == "c(1, 2)"
    @test stanrepr(2:10) == "2:10"
    @test stanrepr(10:2) == "integer(0)"
    @test stanrepr(Int[]) == "integer(0)"
    @test stanrepr([3.0,7.0]) == "c(3.0, 7.0)"
    @test stanrepr(linspace(0,1,3)) == "c(0.0, 0.5, 1.0)"
end

@testset "array" begin
    @test stanrepr([1 2 3; 4 5 6], compact = true) ==
        "structure(c(1,4,2,5,3,6),.Dim=c(2,3))"
end

@testset "dict" begin
    d = Dict(:a => [1,2], :b => 9.0)
    s = "a = c(1, 2)\nb = 9.0\n"
    @test stanrepr(d) == s      # special case for dictionaries and io streams
    let io = IOBuffer()
        standump(io, d)
        @test String(take!(io)) == s
    end
end

@testset "general" begin
    let io = IOBuffer(),
        sd = StanDumpIO(io, compact = true)
        standump(sd, :a => 1, :b => 2) # multiple arguments
        @test String(take!(io)) == "a=1\nb=2\n"
    end
    @test_throws ErrorException stanrepr(:s)      # standalone symbol
    @test_throws ErrorException stanrepr(nothing) # unknown type
end
