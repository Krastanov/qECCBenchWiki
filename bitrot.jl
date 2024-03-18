# Some experimental code that did not end up being used.

using MAT

"""Save an `(errors, nsamples, results)` tuple as a .mat file"""
function matfileresults(filename)
    file = matopen(filename, "r")
    errors = read(file, "errors")
    nsamples = read(file, "nsamples")
    results = read(file, "results")
    close(file)
    return errors, nsamples, results
end

"""Update a .mat file with additional samples in the form of a `(errors, nsamples, results)` tuple"""
function fileresults!(filename, errors, nsamples, results)
    exists = isfile(filename)
    nsamples, results = if exists
        file = matopen(filename, "r")
        olderrors = read(file, "errors")
        oldnsamples = read(file, "nsamples")
        oldresults = read(file, "results")
        close(file)
        if olderrors != errors
            @warn "Overwriting file with different simulated errors parameters"
            nsamples, results
        else
            totalsamples = nsamples .+ oldnsamples
            results .= (results .* nsamples .+ oldresults .* oldnsamples) ./ totalsamples
            nsamples, results
        end
    else
        nsamples, results
    end
    file = matopen(filename, "w")
    write(file, "errors", errors)
    write(file, "nsamples", nsamples)
    write(file, "results", results)
    close(file)
    return errors, nsamples, results
end
