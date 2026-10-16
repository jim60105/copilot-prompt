#!/usr/bin/env python3
"""Decode one private txt2img batch; generate.sh owns rollback and publication."""

import base64
import binascii
import json
from pathlib import Path
import struct
import sys
import zlib


def validate_png(data):
    """Check PNG framing, checksums, and the compressed pixel stream."""
    if not data.startswith(b"\x89PNG\r\n\x1a\n"):
        raise ValueError("image is not PNG data")
    offset = 8
    compressed = bytearray()
    header = False
    while offset + 12 <= len(data):
        length = struct.unpack_from(">I", data, offset)[0]
        end = offset + 12 + length
        if end > len(data):
            raise ValueError("truncated PNG chunk")
        kind = data[offset + 4:offset + 8]
        payload = data[offset + 8:end - 4]
        checksum = struct.unpack_from(">I", data, end - 4)[0]
        if zlib.crc32(data[offset + 4:end - 4]) != checksum:
            raise ValueError("invalid PNG checksum")
        if not header:
            if kind != b"IHDR" or length != 13:
                raise ValueError("missing PNG header")
            width, height = struct.unpack_from(">II", payload)
            if not width or not height:
                raise ValueError("invalid PNG dimensions")
            header = True
        elif kind == b"IHDR":
            raise ValueError("duplicate PNG header")
        if kind == b"IDAT":
            compressed.extend(payload)
        if kind == b"IEND":
            if length or end != len(data) or not compressed:
                raise ValueError("invalid PNG end")
            decoder = zlib.decompressobj()
            pixels = decoder.decompress(compressed)
            if not pixels or not decoder.eof or decoder.unused_data:
                raise ValueError("invalid PNG pixel stream")
            return
        offset = end
    raise ValueError("incomplete PNG image")


def main():
    batch = Path(sys.argv[1])
    with (batch / "response.json").open(encoding="utf-8") as source:
        response = json.load(source)
    if not isinstance(response, dict):
        raise ValueError("API response must be an object")
    images = response.pop("images", None)
    if not isinstance(images, list) or not images:
        raise ValueError("API response must contain a nonempty images array")
    paths = []
    for index, image in enumerate(images):
        if not isinstance(image, str):
            raise ValueError(f"image {index} must be a base64 string")
        decoded = base64.b64decode(image, validate=True)
        validate_png(decoded)
        path = batch / f"image-{index + 1:04d}.png"
        with path.open("xb") as target:
            target.write(decoded)
        paths.append(str(path))
    metadata = batch / "metadata.json"
    with metadata.open("x", encoding="utf-8") as target:
        json.dump(response, target, ensure_ascii=False)
        target.write("\n")
    print(json.dumps({"image_paths": paths, "metadata_path": str(metadata)},
                     separators=(",", ":")))


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, binascii.Error, zlib.error) as error:
        print(f"generate.sh: cannot save batch: {error}", file=sys.stderr)
        sys.exit(1)
