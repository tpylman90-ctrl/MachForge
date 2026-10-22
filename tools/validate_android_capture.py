"""Fail Android CI if the Godot capture is effectively a blank viewport."""
import pathlib
import struct
import sys
import zlib


def paeth(a, b, c):
    p = a + b - c
    pa, pb, pc = abs(p-a), abs(p-b), abs(p-c)
    return a if pa <= pb and pa <= pc else b if pb <= pc else c


def colors_in_png(path):
    data = pathlib.Path(path).read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("capture is not a PNG")
    offset, compressed = 8, []
    width = height = depth = color_type = None
    while offset < len(data):
        size = struct.unpack_from(">I", data, offset)[0]
        kind = data[offset+4:offset+8]
        payload = data[offset+8:offset+8+size]
        if kind == b"IHDR":
            width, height, depth, color_type, comp, filt, interlace = struct.unpack(">IIBBBBB", payload)
            if depth != 8 or color_type not in (2, 6) or interlace:
                raise ValueError("expected a non-interlaced 8-bit RGB/RGBA Android capture")
        elif kind == b"IDAT":
            compressed.append(payload)
        elif kind == b"IEND":
            break
        offset += size + 12
    channels = 4 if color_type == 6 else 3
    raw = zlib.decompress(b"".join(compressed))
    stride = width * channels
    previous = bytearray(stride)
    unique = set()
    # Sample a 100 by 60 grid after reconstructing PNG scanline filters.
    step_x, step_y = max(1, width // 100), max(1, height // 60)
    for y in range(height):
        start = y * (stride + 1)
        filter_type = raw[start]
        encoded = raw[start+1:start+1+stride]
        row = bytearray(stride)
        for i, value in enumerate(encoded):
            left = row[i-channels] if i >= channels else 0
            up = previous[i]
            upper_left = previous[i-channels] if i >= channels else 0
            if filter_type == 1: value += left
            elif filter_type == 2: value += up
            elif filter_type == 3: value += (left + up) // 2
            elif filter_type == 4: value += paeth(left, up, upper_left)
            elif filter_type != 0: raise ValueError(f"unsupported PNG filter {filter_type}")
            row[i] = value & 255
        if y % step_y == 0:
            for x in range(0, width, step_x):
                i = x * channels
                unique.add(tuple(row[i:i+3]))
                if len(unique) >= 10000:
                    return width, height, len(unique)
        previous = row
    return width, height, len(unique)


def main(path):
    width, height, diversity = colors_in_png(path)
    print(f"Android frame: {width}x{height}, {diversity} sampled colors")
    if diversity < 80:
        raise SystemExit("Android frame is nearly uniform; scene/UI may not have rendered")


if __name__ == "__main__":
    main(sys.argv[1])
