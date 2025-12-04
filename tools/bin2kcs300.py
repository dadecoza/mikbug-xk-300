#!/usr/bin/env python3
import sys
import wave
import struct

SAMPLE_RATE = 44100
AMPLITUDE = 16000
BAUD = 300
BIT_DURATION = 1.0 / BAUD
BIT_SAMPLES = int(SAMPLE_RATE * BIT_DURATION)

FREQ_0 = 1200.0   # logic 0
FREQ_1 = 2400.0   # logic 1

LEADER_SECONDS = 30.0


# ------------------------------------------------------------
# Generate one bit as a square wave
# ------------------------------------------------------------
def gen_square_bit(freq):
    samples = []
    half_period = SAMPLE_RATE / (2.0 * freq)
    sign = 1
    next_flip = half_period
    for i in range(BIT_SAMPLES):
        if i >= next_flip:
            sign = -sign
            next_flip += half_period
        samples.append(int(sign * AMPLITUDE))
    return samples


# Precompute bit waves for speed
BIT0 = gen_square_bit(FREQ_0)
BIT1 = gen_square_bit(FREQ_1)


# ------------------------------------------------------------
# Encode one byte as: start bit (0), 8 data bits (LSB first), 2 stop bits (1)
# ------------------------------------------------------------
def byte_wave(value):
    out = []

    # Start bit
    out.extend(BIT0)

    # Data bits (LSB first)
    for i in range(8):
        bit = (value >> i) & 1
        out.extend(BIT1 if bit else BIT0)

    # Stop bits (2)
    out.extend(BIT1)
    out.extend(BIT1)

    return out


def sync():
    out = []
    for i in range(64):
        out.extend(BIT0)
    return out


# ------------------------------------------------------------
# WAV writer
# ------------------------------------------------------------
def write_wav(fname, samples):
    with wave.open(fname, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SAMPLE_RATE)
        data = struct.pack("<{}h".format(len(samples)), *samples)
        w.writeframes(data)


# ------------------------------------------------------------
# Main
# ------------------------------------------------------------
def main():
    if len(sys.argv) != 3:
        print("Usage: bin2kcs300.py input.bin output.wav")
        sys.exit(1)

    infile = sys.argv[1]
    outfile = sys.argv[2]

    # --- Change this to choose load address ---
    begin = 0xE000

    # Read binary
    with open(infile, "rb") as f:
        data = f.read()

    # Compute end address
    end = begin + len(data) - 1

    print(f"Binary size: {len(data)} bytes")
    print(f"Begin address: ${begin:04X}")
    print(f"End address:   ${end:04X}")

    # Data length check
    expected_len = end - begin + 1
    if len(data) != expected_len:
        print("ERROR: size mismatch!")
        sys.exit(1)

    samples = []

    # ------------------------------------------------------------
    # 30-second leader of 0xFF characters
    # Each byte is 11 bit-times → byte duration = 11 * BIT_DURATION
    # ------------------------------------------------------------
    bytes_in_leader = int(LEADER_SECONDS / (11 * BIT_DURATION))
    print(f"Adding leader: {bytes_in_leader} bytes of 0xFF...")

    for _ in range(bytes_in_leader):
        samples.extend(byte_wave(0xFF))

    # ------------------------------------------------------------
    # Build cassette block
    # ------------------------------------------------------------
    block = bytearray()

    block.append(0x53)  # "S" start character

    # Addresses
    block.append((begin >> 8) & 0xFF)
    block.append(begin & 0xFF)
    block.append((end >> 8) & 0xFF)
    block.append(end & 0xFF)

    # Data
    block.extend(data)

    # Checksum (two's complement)
    checksum = (-sum(block[1:])) & 0xFF
    block.append(checksum)

    print(f"Checksum: ${checksum:02X}")

    # Encode block
    for b in block:
        samples.extend(byte_wave(b))

    samples.extend(sync())

    print(f"Writing WAV to: {outfile}")
    write_wav(outfile, samples)
    print("Done.")


if __name__ == "__main__":
    main()
