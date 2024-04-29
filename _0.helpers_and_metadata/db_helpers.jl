module DBHelpers

using SQLite
using DBInterface

include("../_0.helpers_and_metadata/helpers.jl")

using .Helpers: logrange, instancenameof, skipredundantprefix, typenameof

const CONN = DBInterface.connect(SQLite.DB, "codes/results.sqlite")
SQLite.busy_timeout(CONN, 100)

DBInterface.execute(
    CONN,
    """CREATE TABLE IF NOT EXISTS results
    (code TEXT, decoder TEXT, setup TEXT, error REAL, nsamples INTEGER, logx REAL, logz REAL,
        PRIMARY KEY (code, decoder, setup, error))"""
)
DBInterface.execute(CONN, "PRAGMA journal_mode=WAL")

function dbrow(code, decoder, setup, e)
    coden = skipredundantprefix(instancenameof(code))
    decodern = skipredundantprefix(decoder)
    setupn = skipredundantprefix(setup)
    res = DBInterface.execute(
        CONN,
        "SELECT * FROM results WHERE code=? AND decoder=? AND setup=? AND error=?",
        (coden, decodern, setupn, e))
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
    coden = skipredundantprefix(instancenameof(code))
    decodern = skipredundantprefix(decoder)
    setupn = skipredundantprefix(setup)
    while true # retry on sqlite busy
        try
            newrow = DBInterface.transaction(CONN) do
                old = dbrow(code, decoder, setup, e)
                newn, newlx, newlz = if isnothing(old)
                    n, lx, lz
                else
                    newn = n + old.nsamples
                    newn, (lx * n + old.logx * old.nsamples) / newn, (lz * n + old.logz * old.nsamples) / newn
                end
                newrow = coden, decodern, setupn, e, newn, newlx, newlz
                DBInterface.execute(
                    CONN,
                    "REPLACE INTO results (code, decoder, setup, error, nsamples, logx, logz) VALUES (?, ?, ?, ?, ?, ?, ?)",
                    newrow
                )
                newrow
            end
            return newrow
        catch e
            if e == SQLite.SQLiteException("database is locked")
                @debug "Database locked, retrying..."
            else
                rethrow(e)
            end
        end
    end
end

end
