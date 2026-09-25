#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#
# GNU Radio Python Flow Graph
# Title: RTL-SDR APRS RX
# RTL-SDR -> NBFM demod -> PulseAudio sink (direwolf_rx) for Direwolf RX channel 2

from gnuradio import analog, audio, filter, gr
from gnuradio.filter import firdes
import osmosdr
import signal
import sys


class rx_aprs(gr.top_block):

    def __init__(self):
        gr.top_block.__init__(self, "RTL-SDR APRS RX", catch_exceptions=True)

        ##################################################
        # Variables
        ##################################################
        samp_rate    = 1920000
        channel_rate = 192000
        audio_rate   = 48000
        center_freq  = 434650000      # 250 kHz below 434.9 MHz, off the RTL-SDR DC spike
        sig_offset   = 250000 + 1945  # back on frequency + measured tuner error
        squelch_db   = -45.0          # not calibrated for the 15 kHz filter; left permissive

        ##################################################
        # Blocks
        ##################################################
        self.source = osmosdr.source(args="numchan=1 rtl=0")
        self.source.set_sample_rate(samp_rate)
        self.source.set_center_freq(center_freq, 0)
        self.source.set_gain_mode(False, 0)
        self.source.set_gain(30, 0)
        self.source.set_freq_corr(0, 0)
        self.lpf = filter.freq_xlating_fir_filter_ccc(
            samp_rate // channel_rate,
            # keep the cutoff at 15 kHz -- narrower truncates the FM sidebands
            firdes.low_pass(1.0, samp_rate, 15000, 2000),
            sig_offset,
            samp_rate
        )
        self.squelch = analog.pwr_squelch_cc(squelch_db, 1e-4, 0, False)
        self.nbfm = analog.nbfm_rx(
            audio_rate=audio_rate,
            quad_rate=channel_rate,
            tau=10e-6,     # flat across the AFSK band; unstable below ~6.6e-6
            max_dev=6e3,   # tracks measured deviation (~1750 Hz), not nominal
        )
        self.dcblock = filter.dc_blocker_ff(256, True)
        self.sink = audio.sink(audio_rate, "pulse", True)

        ##################################################
        # Connections
        ##################################################
        self.connect(self.source, self.lpf, self.squelch, self.nbfm,
                     self.dcblock, self.sink)


def main():
    tb = rx_aprs()
    tb.start()

    def sig_handler(sig=None, frame=None):
        tb.stop()
        tb.wait()
        sys.exit(0)

    signal.signal(signal.SIGINT, sig_handler)
    signal.signal(signal.SIGTERM, sig_handler)

    tb.wait()


if __name__ == '__main__':
    main()
