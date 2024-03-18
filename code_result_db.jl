using SQLite
using DBInterface

const CONN = DBInterface.connect(SQLite.DB, "codes/results.sqlite")

let
    stmt = DBInterface.prepare(
        CONN,
        """CREATE TABLE IF NOT EXISTS results
        (code TEXT, decoder TEXT, setup TEXT, error REAL, nsamples INTEGER, logx REAL, logz REAL,
         PRIMARY KEY (code, decoder, setup, error))"""
    )
    results = DBInterface.execute(stmt)
end

function dbrow(code, decoder, setup, e)
    code = string(code)
    decoder = string(decoder)
    setup = string(setup)
    res = DBInterface.execute(
        CONN,
        "SELECT * FROM results WHERE code=? AND decoder=? AND setup=? AND error=?",
        (code, decoder, setup, e))
    isempty(res) ? nothing : first(res)
end

function dbnarray(codes, decoders, setups, errors)
    nᶜ = length(codes)
    nᵈ = length(decoders)
    nˢ = length(setups)
    nᵉ = length(errors)
    narray = zeros(nᵉ, 2, nᶜ, nᵈ, nˢ)
    for iᶜ in 1:nᶜ
        for iᵈ in 1:nᵈ
            for iˢ in 1:nˢ
                for iᵉ in 1:nᵉ
                    row = dbrow(codes[iᶜ], decoders[iᵈ], setups[iˢ], errors[iᵉ])
                    narray[iᵉ, :, iᶜ, iᵈ, iˢ] .= isnothing(row) ? NaN : (row.logx, row.logz)
                end
            end
        end
    end
    return narray
end

function dbrow!(code, decoder, setup, e, n, le)
    dbrow!(code, decoder, setup, e, n, le, le)
end

function dbrow!(code, decoder, setup, e, n, lx, lz)
    code = string(code)
    decoder = string(decoder)
    setup = string(setup)
    old = dbrow(code, decoder, setup, e)
    newn, newlx, newlz = if isnothing(old)
        n, lx, lz
    else
        newn = n + old.nsamples
        newn, (lx * n + old.logx * old.nsamples) / newn, (lz * n + old.logz * old.nsamples) / newn
    end
    newrow = code, decoder, setup, e, newn, newlx, newlz
    res = DBInterface.execute(
        CONN,
        "REPLACE INTO results (code, decoder, setup, error, nsamples, logx, logz) VALUES (?, ?, ?, ?, ?, ?, ?)",
        newrow
    )
    return newrow
end
