# 0012 — One line contract, many input adapters

- **Status:** Accepted · 12 Nov 2026
- **Answers:** spec §11 Q2 (does pasted text use the same pipeline as a URL?)

## Decision

"Everything goes into that format. How it gets there depends on the input."

Every input is an **adapter** that produces the ADR 0011 contract. After the
adapter, all inputs share the same validation, ingredient resolution, scoring
and review screen.

| Adapter | Path | v1? |
|---|---|---|
| URL | fetch → JSON-LD `Recipe` (fast path) → LLM over page text (fallback) | ✔ |
| Pasted text | skip fetch → LLM | ✔ |
| Share-sheet URL | same as URL | ✔ |
| Photo / OCR (cookbooks) | OCR → LLM | ✗ (§10) |
| Video (TikTok/Reels) | transcript/caption → LLM | ✗ (§10) |

JSON-LD is the structured recipe data many sites embed for search engines; when
present it gives us the lines without an LLM call.

The result records which path ran (`json_ld` / `llm_html` / `llm_text`) for
accuracy measurement; the UI never branches on it.

## Consequences

Adding photo import later is a new adapter, not a new pipeline or screen.
