% matched_filter applies a root-raised cosine filter to the input signal.
% The filter is designed based on the oversampling factor, rolloff factor, and filter length provided in the configuration structure.
% The filtered signal is obtained by convolving the input signal with the filter coefficients.
%
% Inputs:
%   - signal: Input signal to be filtered.
%   - os_factor: Oversampling factor (e.g., 4).
%   - mf_length: One-sided filter length. The total number of filter coefficients is 2*mf_length + 1.
%   - conf: Configuration structure containing the rolloff factor for the filter design.
%
% Output:
%   - filtered_signal: Signal filtered using the root-raised cosine filter.

function filtered_signal = matched_filter(signal, conf)

    h = rrc(conf.os_factor_preamble, conf.rolloff, conf.tx_filter_len);
    filtered_signal = conv(signal, h, "same");
end