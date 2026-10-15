---
name: story-bible-writer
description: Write a Higgsfield Global Film Festival story bible — logline, look lock, cast/locations (Soul-ID plan), beat sheet, shot list, audio plan, credit budget, and festival compliance checklist. Precondition for higgsfield-soul-id and higgsfield-generate.
version: 0.1.0
execution-mode: advisory
argument-hint: "<premise or logline, or 'propose 3 concepts'>"
category: governance-compliance
status: candidate
---

# Story Bible Writer

> A film only counts if it clears the Minimal Viable Submission. The bible is where eligibility is won or lost before a single credit is spent.

Produces a festival-ready story bible for the **Higgsfield Global Film Festival** ($1M prize pool, 14 placements). Every bible is eligible-by-construction: it encodes the hard constraints so downstream `higgsfield-soul-id` and `higgsfield-generate` work cannot accidentally disqualify the entry.

## When to Use
- Before any higgsfield cinematic generation for a short film
- User says "story bible", "screenplay", "beat sheet", "shot list", or "short film"
- Starting a Higgsfield Global Film Festival entry

## Festival constraints (encode in every bible — verify before sign-off)

| Constraint | Value | Bible impact |
|---|---|---|
| Runtime | **Min 3:00 (hard)**, rec 3-5 min | Shot list must sum ≥ 180s |
| Aspect | 16:9 or 21:9 only | Lock one in look bible |
| Format | MP4/MOV, up to 4K | Post plan handles export |
| Generation | All video/image on higgsfield.ai, any platform model | Shot list cites model per shot |
| **No real person's face or voice** | Not even your own — hard rule | **Soul-ID refs MUST be synthetic/AI-generated faces** |
| Audio | AI-generated music/voice/sound, rights held, uploaded to project | Audio plan section |
| Submission | Final cut + Higgsfield watermark + packshot + public post (IG/YT/X/Reddit) | Delivery checklist |
| Create in Public | ≥10 gens + ≥15s cut + poster + logline → top 50 to jury shortlist | Publish-gate section |
| Teams | Solo or up to 4, one Team Leader | Cast/credits section |
| Deadline | **Sep 14, 2026** (extended) | Backward-plan from today |

## Execution

### 1. Resolve premise
- If argument is a premise/logline → use it.
- If "propose 3 concepts" or empty → propose 3 loglines (one-line each, distinct genres), ask user to pick.
- Confirm target runtime (default 3-5 min), aspect (default 21:9), solo/team.

### 2. Lock the look bible (write once, reuse every shot)
Pick and record fixed values — these become CLI flags reused across every `generate workflow` call:
- `genre_id`, `era_id`, `style_id`
- `camera_model_id`, `camera_lens_id`, `camera_aperture_id`
- `light_id` (preset/custom/user), `color_palette`
- `aspect_ratio`, `resolution` (target 1080p master, upscale to 4K in post)
- One sentence: the visual signature a stranger would recognize.

### 3. Cast & locations → Soul-ID plan
- For each character: name, role, one-paragraph description, **synthetic reference source** (generate refs via `freemodel-generate`/`cinematic_studio_image` first — NEVER a real face).
- For each location: name, description, synthetic reference source.
- Output a Soul-ID training checklist: `hf soul-id create --name <X> --soul-cinematic --image <id> ×5`.
- Chain to: `[higgsfield-soul-id]` after bible is approved.

### 4. Beat sheet
Structure the runtime into beats (e.g., 5 beats for a 3-min film). Each beat: purpose, emotional turn, approximate duration.

### 5. Shot list (the production contract)
One row per shot. Columns:
- Shot #, beat, duration (s), `mode` (t2v / omni_reference / video_edit / video_extension)
- Prompt (cinematic, camera-aware, references the locked look)
- References (keyframe image ID, Soul-ID, start_image)
- Model (`cinematic_studio_video_4_0` default; cite fallback if needed)
- `generate_audio` (true/false)
- Estimated credits — run `hf generate cost <model> --prompt "..." --duration N --resolution 1080p` before locking

**Sum of durations must be ≥ 180s.** Flag if under.

### 6. Audio plan
- Diegetic: `generate_audio: true` on Cinema Studio shots
- Narration: pick a voice from `hf voices list`, write narration lines
- Music/sound design: AI-generated, rights held, upload to project

### 7. Credit budget
Account: `hf account status`. Reserve ~30% for retakes. Total the shot-list estimates; flag if projected spend exceeds available minus reserve.

### 8. Festival compliance checklist (must be all-true before chain-out)
- [ ] Runtime ≥ 3:00
- [ ] Aspect 16:9 or 21:9
- [ ] No real person's face or voice in any input
- [ ] All generation on higgsfield.ai
- [ ] Audio AI-generated, rights held
- [ ] Watermark + packshot retained on final
- [ ] Public-post plan (IG/YT/X/Reddit)
- [ ] Create-in-Public gate met (≥10 gens, ≥15s cut, poster, logline) OR explicit private-submit decision

## Output Format
```
Story Bible | <title> | <runtime> | <aspect>
══════════════════════════════════════════
Logline: <one line>
Look lock: <genre/era/camera/light/color signature>
Cast: <chars with Soul-ID plan>
Locations: <with Soul-ID plan>
Beat sheet: <N beats>
Shot list: <N shots, total = <Xs>>
Audio: <diegetic/narration/music>
Credit budget: <est>/<avail> (reserve <R>)
Compliance: <all-true / FAILURES: ...>
Next: [higgsfield-soul-id] → [higgsfield-generate]
```

Save the bible to `_internal/film/<slug>-bible.md` (operator confirms path).

## Skill Chains
- **After**: `[higgsfield-soul-id]` (train cast/location refs) → `[higgsfield-generate]` (keyframes then shots)
- **Before**: `[brainstorm]` if premise is unresolved

## Constraints
- READ-ONLY — produces a document, no generation, no commits
- Never propose a real person's face/voice as a Soul-ID source — synthetic only
- Always run `hf generate cost` before locking shot-list estimates
- Deadline-aware: if invoked after the festival window closes, note it and treat as a general short-film bible
