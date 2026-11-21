"""Data-format conversion only; synthetic PLINK metadata is explicitly recorded."""
import argparse
import hashlib
import json
from pathlib import Path
import numpy as np

parser = argparse.ArgumentParser()
parser.add_argument("case", choices=("cattle", "maize"))
parser.add_argument("source", type=Path)
parser.add_argument("prefix", type=Path)
parser.add_argument("--verify-existing", action="store_true")
args = parser.parse_args()
paths = [Path(str(args.prefix) + suffix) for suffix in (".bed", ".bim", ".fam", ".json")]
if args.verify_existing and not all(p.is_file() for p in paths):
    raise SystemExit("Verification requires the complete existing triplet and manifest.")
if not args.verify_existing and any(p.exists() for p in paths):
    raise SystemExit("Conversion outputs already exist; preserve them and choose a new prefix.")
args.prefix.parent.mkdir(parents=True, exist_ok=True)
with np.load(args.source, allow_pickle=False) as archive:
    if archive.files != ["arr_0"]:
        raise ValueError("Unexpected genotype NPZ fields")
    X = archive["arr_0"]
n, p = X.shape
expected = {"cattle": (5024, 42551), "maize": (1458, 75304)}
if (n, p) != expected[args.case] or not np.issubdtype(X.dtype, np.integer):
    raise ValueError("Unexpected genotype dimensions or type")
code = np.array([3, 2, 0], dtype=np.uint8)  # 0/1/2 copies of synthetic BIM allele A.
byte_count = (n + 3) // 4
if not args.verify_existing:
    with paths[0].open("wb") as stream:
        stream.write(bytes((0x6C, 0x1B, 0x01)))
        for start in range(0, p, 256):
            block = X[:, start : start + 256]
            if block.min() < 0 or block.max() > 2:
                raise ValueError("Expected exact observed 0/1/2 dosages")
            encoded = np.zeros((block.shape[1], byte_count * 4), dtype=np.uint8)
            encoded[:, :n] = code[block.T]
            encoded = encoded.reshape(block.shape[1], byte_count, 4)
            packed = encoded[:, :, 0] | (encoded[:, :, 1] << 2) | (encoded[:, :, 2] << 4) | (encoded[:, :, 3] << 6)
            stream.write(packed.tobytes(order="C"))
    with paths[1].open("w", encoding="ascii", newline="\n") as stream:
        for j in range(p):
            stream.write(f"1\tgpbench_{args.case}:column:{j + 1}\t0\t{j + 1}\tA\tC\n")
    with paths[2].open("w", encoding="ascii", newline="\n") as stream:
        for i in range(n):
            stream.write(f"GPCT_SYNTHETIC\tgpbench_{args.case}:row:{i + 1:06d}\t0\t0\t0\t-9\n")
# Check metadata as well as independently decoding every serialized dosage.
if paths[0].stat().st_size != 3 + p * byte_count:
    raise ValueError("Unexpected BED length")
with paths[0].open("rb") as stream:
    if stream.read(3) != bytes((0x6C, 0x1B, 0x01)):
        raise ValueError("Invalid SNP-major BED header")
with paths[1].open(encoding="ascii") as stream:
    for j in range(p):
        if stream.readline().split() != ["1", f"gpbench_{args.case}:column:{j+1}", "0", str(j+1), "A", "C"]:
            raise ValueError("BIM annotations differ from the synthetic contract")
    if stream.readline():
        raise ValueError("Extra BIM records")
with paths[2].open(encoding="ascii") as stream:
    for i in range(n):
        if stream.readline().split() != ["GPCT_SYNTHETIC", f"gpbench_{args.case}:row:{i+1:06d}", "0", "0", "0", "-9"]:
            raise ValueError("FAM annotations differ from the synthetic contract")
    if stream.readline():
        raise ValueError("Extra FAM records")
raw = np.memmap(paths[0], dtype=np.uint8, mode="r", offset=3, shape=(p, byte_count))
decode = np.array([2, -1, 1, 0], dtype=np.int8)
for start in range(0, p, 256):
    chunk = raw[start : start + 256]
    calls = np.empty((chunk.shape[0], byte_count * 4), dtype=np.int8)
    for offset in range(4):
        calls[:, offset::4] = decode[(chunk >> (2 * offset)) & 3]
    if not np.array_equal(calls[:, :n].T, X[:, start : start + 256]):
        raise ValueError("Serialized BED dosage round-trip failed")
with args.source.open("rb") as source_file:
    source_sha256 = hashlib.file_digest(source_file, "sha256").hexdigest()
manifest = {
    "dataset": f"gpbench_{args.case}", "individuals": n, "markers": p,
    "source_npz_sha256": source_sha256,
    "synthetic_annotations": True,
    "sample_ids": "source-row surrogates; not original biological identities",
    "marker_ids": "source-column surrogates; not mapped SNP identifiers",
    "chromosome": "all markers on synthetic contig 1; not a biological chromosome",
    "position": "one-based source-column index; not a genomic position",
    "alleles": "synthetic A/C; source dosage counts A; not biological allele identities",
    "source_order_preserved": True, "all_dosages_roundtrip_equal": True,
    "allowed_use": "full-marker prediction and genotype-count QC",
    "excluded_uses": "biological LOCO, genomic-distance LD, allele harmonization, positional interpretation",
}
if args.verify_existing:
    if json.loads(paths[3].read_text(encoding="utf-8")) != manifest:
        raise ValueError("Existing manifest differs from the verified source and metadata")
else:
    paths[3].write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
print(json.dumps({"case": args.case, "n": n, "p": p, "dosage_roundtrip": "all equal", "synthetic_annotations": True}))
