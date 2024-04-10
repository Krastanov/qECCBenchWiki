import LDPCDecoders
using Test

function test_bpropdecoder()
    H = LDPCDecoders.parity_check_matrix(1000,10,9);
    decoder = LDPCDecoders.BeliefPropagationDecoder(H, 0.01, 100);
    count = 0
    for _ in 1:1000
        error = rand(1000) .< 0.01;
        syndrome = (H * error) .% 2;
        guess, success = LDPCDecoders.decode!(decoder, syndrome);
        count += error == guess
    end
    return 1-count/1000
end

function test_bitflipdecoder()
    H = LDPCDecoders.parity_check_matrix(1000,10,9);
    decoder = LDPCDecoders.BitFlipDecoder(H, 0.01, 100);
    count = 0
    for _ in 1:1000
        error = rand(1000) .< 0.01;
        syndrome = (H * error) .% 2;
        guess, success = LDPCDecoders.decode!(decoder, syndrome);
        count += error == guess
    end
    return 1-count/1000
end

function test_bpropdecoder_old()
    H = LDPCDecoders.parity_check_matrix(1000,10,9);
    decoder = LDPCDecoders.BeliefPropagationDecoder(H, 0.01, 100);
    count = 0
    for _ in 1:1000
        error = rand(1000) .< 0.01;
        syndrome = (H * error) .% 2;
        LDPCDecoders.reset!(decoder)
        LDPCDecoders.syndrome_decode!(decoder, decoder.scratch, syndrome)
        count += error == decoder.scratch.err
    end
    return 1-count/1000
end

##

@test test_bitflipdecoder()
@test test_bpropdecoder() < 0.001
@test test_bpropdecoder_old() < 0.001
