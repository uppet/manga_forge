# Local media backends

The verified host uses WSL for orchestration and `delegate_runner` to invoke the
Windows GPU stack.

## Illustration

- Animagine XL 4.0: anime/manga illustration and Danbooru-style tagging.
- Z-Image Turbo: fast cel-shaded drafts and cinematic keyframes.
- FLUX.2 klein base: general or more realistic source art.
- Host root: `S:\\bld\\om-video`.
- Output root: `S:\\bld\\om-video\\ComfyUI\\output`.

Use reference-image conditioning for recurring characters. Text-only redraws do
not satisfy the character consistency contract.

## Video

The local H3 FL2VA pipeline animates approved first/last frames and can synthesize
audio. Use it only for pre-rendered media. Its community license restricts use
and display in the US, EU, UK, and South Korea; do not place H3 output in a global
build without a separately reviewed license.

## Operational rule

The host and proxy configuration belongs in `tools/windows/host_config.json`, not
inside prompts, manifests, or portable skill instructions.
