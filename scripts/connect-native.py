"""Add the team skill path to a project JSON(C) without rewriting user settings."""
import json
import os
from pathlib import Path
import re
import sys
import tempfile


SKILLS = "../fieldnotes-native/.agents/skills"
STRING = r'"(?:\\.|[^"\\])*"'


def add_source(text):
    # Mask comments and trailing commas but keep offsets into the original text.
    def mask(match):
        token = match[0]
        return token if token.startswith('"') else " " * len(token)

    clean = re.sub(STRING + r"|//[^\r\n]*|/\*.*?\*/", mask, text, flags=re.S)
    clean = re.sub(STRING + r"|,(?=\s*[}\]])", mask, clean)
    config = json.loads(clean)
    if not isinstance(config, dict):
        raise ValueError("Expected an OpenCode config object.")
    root = clean.index("{") + 1
    if "skills" not in config:
        field = '"skills": [' + json.dumps(SKILLS) + ']'
        return text[:root] + field + (", " if config else "") + text[root:]
    if not isinstance(config["skills"], list):
        raise ValueError("Expected an array in the OpenCode skills setting.")
    if SKILLS in config["skills"]:
        return text

    def skip_space(pos):
        while clean[pos].isspace():
            pos += 1
        return pos

    pos = skip_space(root)
    decoder = json.JSONDecoder()
    while clean[pos] != "}":
        key, end = decoder.raw_decode(clean, pos)
        value = skip_space(skip_space(end) + 1)  # The validated key ends before ':'.
        if key == "skills":
            pos = value + 1
            return text[:pos] + json.dumps(SKILLS) + (", " if config[key] else "") + text[pos:]
        _, end = decoder.raw_decode(clean, value)
        pos = skip_space(end)
        if clean[pos] == ",":
            pos = skip_space(pos + 1)
    raise ValueError("Could not locate the skills array.")


def connect(project):
    for name in ("opencode.jsonc", "opencode.json"):
        path = project / name
        if path.is_file():
            break
    else:
        path = project / "opencode.jsonc"
        with path.open("x", encoding="utf-8") as out:
            json.dump({"skills": [SKILLS]}, out, indent=2)
            out.write("\n")
        return

    original = path.read_bytes()
    bom = original.startswith(b"\xef\xbb\xbf")
    text = original.decode("utf-8-sig")
    updated = add_source(text)
    if updated == text:
        return
    with tempfile.NamedTemporaryFile(dir=project, delete=False) as out:
        tmp = Path(out.name)
        out.write(updated.encode("utf-8-sig" if bom else "utf-8"))
    try:
        if path.is_symlink() or path.read_bytes() != original:
            raise ValueError(f"Cannot replace a linked or concurrently edited config: {path}")
        os.replace(tmp, path)
    finally:
        tmp.unlink(missing_ok=True)


if __name__ == "__main__":
    try:
        connect(Path(sys.argv[1]))
    except (ValueError, OSError) as error:
        sys.exit(f"OpenCode config: {error}")
