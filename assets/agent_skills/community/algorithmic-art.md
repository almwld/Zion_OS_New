---
name: algorithmic-art
description: "Create original, self-contained, and verified p5.js generative art from an algorithmic philosophy. Hardened for reproducibility, safety, and measurable quality."
version: 0.2.0
execution-mode: advisory
category: dev-tools
status: candidate
providers:
  optional: [node(emitted)]
---

# Algorithmic Art

## Mission

Create a p5.js generative art artifact from an algorithmic philosophy. Output a `.md` philosophy document and a single, self-contained `.html` artifact. A separate `.js` file may be emitted as a human-readable algorithm extract, but the HTML must never depend on it.

## Red-team posture

This skill has been wargamed around the following failure modes. Each is now a veto point: if the incoming request or the proposed output violates one, stop and escalate to the user.

1. **Quality theater over verifiable quality**
   - Original flaw: the skill encouraged repeating superlatives like "meticulously crafted" and "master-level" rather than defining quality.
   - Hardening: quality is defined by a smoke-test checklist. The philosophy describes the algorithm and its intended aesthetic, not the model's own expertise.

2. **Infinite runtime / resource exhaustion**
   - Original flaw: no limits on canvas size, particle count, or animation duration.
   - Hardening: canvas must not exceed 1200x1200 by default; particle/object counts must target 60fps on typical hardware; every `draw()` loop must have a stop condition (`noLoop()` or a bounded `maxIterations`).

3. **Broken or non-reproducible seeds**
   - Original flaw: seed controls were described but not enforced.
   - Hardening: `randomSeed(params.seed)` and `noiseSeed(params.seed)` must be called before any `random()` or `noise()` use. Reset must restore defaults. Same seed must produce identical output.

4. **Contradictory output format**
   - Original flaw: the skill asked for `.md`, `.html`, and `.js` while also saying the HTML is a single inline artifact.
   - Hardening: the HTML is the deliverable and is self-contained. The `.js` is optional reference only. The `.md` is the philosophy.

5. **Code-injection / exfiltration / malicious art**
   - Original flaw: no guardrails against injecting user-supplied code into the HTML or using `eval`, `innerHTML`, or network calls.
   - Hardening: do not use `eval`, `document.write`, `innerHTML` for algorithm content, `fetch`, `XMLHttpRequest`, or `WebSocket`. The only allowed external script is the p5.js CDN. Do not embed hidden, deceptive, or offensive messages. Halt if the user requests trackers, malware, or shock content.

6. **Template drift / bypass**
   - Original flaw: model can be tempted to write HTML from scratch.
   - Hardening: `templates/viewer.html` must be read first. If it is missing, stop. Keep Anthropic branding, sidebar, seed, and actions sections intact.

7. **Missing verification**
   - Original flaw: no explicit check that the artifact works.
   - Hardening: run syntax validation, open or preview the HTML, test the seed controls, check the console, and verify the PNG download.

8. **Accessibility / safe defaults**
   - Original flaw: no accessibility or motion-safety guidance.
   - Hardening: respect `prefers-reduced-motion` where possible; avoid rapid flashing; keep UI color contrast above 3:1; provide a pause or bounded-run default.

## Output location and naming

- Write outputs to `_internal/art/`.
- Use `kebab-case` for the movement name.
- Required files:
  - `_internal/art/{movement-name}-philosophy.md`
  - `_internal/art/{movement-name}.html`
- Optional file:
  - `_internal/art/{movement-name}.js` — a human-readable extract of the algorithm, not imported by the HTML.

## Step 1: Algorithmic philosophy

Before writing code, write a `.md` philosophy that an implementer can turn into an algorithm. Treat this as a specification, not a marketing document.

### Requirements
- 4-6 concise paragraphs.
- Name the movement in 1-2 words.
- Explain the computational idea: forces, noise, particles, fields, recursion, tessellation, harmonics, etc.
- State the conceptual seed explicitly if one exists. The reference should be subtle and inoffensive — never a hidden message, slur, or deceptive signal.
- Describe what should happen parametrically and temporally.
- Avoid manipulative claims. Use concrete language: "the algorithm uses X to produce Y" rather than "a master crafted X".
- Do not include source code in the `.md`.

### Anti-patterns
- Repeating the same concept across multiple paragraphs.
- Using vague superlatives instead of algorithmic detail.
- Embedding a conceptual seed that could be read as a hidden or harmful message.

## Step 2: Read the template

1. Use the Read tool to open `templates/viewer.html`.
2. If the file is missing, stop and report.
3. Keep fixed sections exactly as shown:
   - layout (header, sidebar, main canvas area)
   - Anthropic branding (colors, fonts, gradients)
   - seed section (display, Prev/Next, Random, Jump)
   - actions section (Regenerate, Reset, Download PNG)
4. Replace only variable sections:
   - title and subtitle
   - parameter controls
   - color controls (if any)
   - the p5.js algorithm inside the `<script>` block

## Step 3: Implement the HTML

### Core rules
- All JavaScript must be inline. Do not `<script src='...'>` the algorithm from the optional `.js` file.
- The only allowed external script is `https://cdnjs.cloudflare.com/ajax/libs/p5.js/1.7.0/p5.min.js`.
- Canvas must not exceed 1200x1200 by default. 1600x1600 is an absolute hard ceiling.
- The `draw()` loop must terminate. Use `noLoop()` after a bounded number of frames, or provide an explicit user control to stop.

### Parameter structure

Use a `params` object. Always include `seed`. Add 3-8 tunable values that map to real system properties, not to preset patterns.

```javascript
let params = {
  seed: 12345,
  // quantities, scales, probabilities, ratios, angles, thresholds
};

let defaultParams = JSON.parse(JSON.stringify(params)); // deep copy
```

### Seeded randomness

Call before any random/noise use:

```javascript
randomSeed(params.seed);
noiseSeed(params.seed);
```

### Algorithm skeleton

```javascript
function setup() {
  let canvas = createCanvas(1200, 1200);
  canvas.parent('canvas-container');
  initializeSystem();
}

function initializeSystem() {
  randomSeed(params.seed);
  noiseSeed(params.seed);
  // build the system from params
  background(250, 249, 245);
}

function draw() {
  // update and display
  // stop after maxFrames or call noLoop()
}
```

### UI controls
- Numeric parameters: `<input type='range'>` with `min`, `max`, `step`, `value`, `oninput`, and `onchange`.
- Color parameters: `<input type='color'>` only if the palette is intended to be tunable. Omit the Colors section for monochrome or fixed palettes.
- Seed controls: must include Prev, Next, Random, Jump, and display.
- Actions: Regenerate, Reset, Download PNG.

### Performance and safety
- Avoid `eval`, `document.write`, `innerHTML` for untrusted strings, `fetch`, `XMLHttpRequest`, `WebSocket`.
- Cap particle or object counts to keep `draw()` near 60fps on average hardware.
- Avoid unbounded recursion, unbounded growth, or infinite memory accumulation.
- If using animation, respect `prefers-reduced-motion` by defaulting to a short, bounded run.

## Step 4: Verify before delivery

Do not deliver without at least:

1. **Syntax check** — extract the inline script and run `node --check` on it, or otherwise validate JavaScript syntax.
2. **Open / preview** — open the HTML in a browser or start a local server and preview it in a browser.
3. **Smoke test** — with seed `12345`, click Next, Random, Reset, change a parameter, and click Download PNG.
4. **Console check** — no errors or warnings.
5. **Reproducibility** — same seed produces the same output.

If any step fails, fix it before reporting done.

## Optional `.js` extract

The `.js` file is a convenience for the user or reviewer. It must:
- Contain the same algorithm as the HTML `<script>`.
- Be standalone and readable.
- Not be imported by the HTML.
- Pass `node --check`.

## Examples (redacted)

Use the original five examples as algorithmic starting points, but rewrite the adjective-laden language into concrete mechanics:

- **Organic Turbulence**: layered Perlin-noise flow field, particle trails, velocity-mapped color, run-to-equilibrium.
- **Quantum Harmonics**: grid of phase-carrying particles, sine-wave phase evolution, interference nodes and voids.
- **Recursive Whispers**: branching with randomized but ratio-constrained angles, diminishing line weights, optional L-systems.
- **Field Dynamics**: vector fields from math or noise, particles seeded at edges, traces show force lines.
- **Stochastic Crystallization**: randomized point packing or Voronoi relaxation, color from cell geometry, run-to-equilibrium.

## Anti-patterns (hard stop)

- Writing HTML from scratch.
- Importing the algorithm from a separate `.js` file.
- Repeating empty superlatives instead of describing mechanics.
- Leaving an infinite `draw()` loop.
- Skipping the smoke test.
- Embedding hidden or harmful messages in the conceptual seed.
- Exceeding 1600x1600 canvas or overloading particle count.

## Resources

- `templates/viewer.html`: the only allowed starting point.
- `templates/generator_template.js`: reference for parameter organization, seeding, and p5.js structure. Do not copy the example algorithm wholesale.
