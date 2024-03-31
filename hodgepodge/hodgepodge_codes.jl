# Codes that do not have a proper construction algorithm available, rather are provided in "hardcoded" fashion, because a friend thought they are of use.

module Hodgepodge

using QuantumClifford
using QuantumClifford.ECC
import QuantumClifford.ECC: AbstractECC, parity_checks, parity_checks_x, parity_checks_z

abstract type HodgepodgeCode <: QuantumClifford.ECC.AbstractECC end

function load_nithin(filename)
    fid = open(filename)
    col, row = parse.(Int, split(readline(fid)))
    H = zeros(Bool, row, col)
    for c in 1:col
        idx = parse.(Int, split(readline(fid)))
        H[idx[2:end],c] .= true
    end
    close(fid)
    H
end


struct NithinCode <: HodgepodgeCode
end

nc() = CSS(load_nithin((@__DIR__)*"/nithin/QC_dv4dc8_psto_29_12_2_4_hx"), load_nithin((@__DIR__)*"/nithin/QC_dv4dc8_psto_29_12_2_4_hz"))
parity_checks(::NithinCode) = parity_checks(nc())
parity_checks_x(::NithinCode) = parity_checks_x(nc())
parity_checks_z(::NithinCode) = parity_checks_z(nc())

end
