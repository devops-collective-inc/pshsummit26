---
marp: true
theme: summit-2026
paginate: true
---

<!-- _class: title -->

# Engineering Platforms for Engineers who Engineer Platforms


<p class="name">Ryan Coates</p>
<p class="handle">https://rdc.dev</p>

---

<!-- _class: sponsors -->
<!-- _paginate: skip -->

# Thanks!

---

# "DevOps Is Dead."

The headline that launched a thousand LinkedIn arguments.

<div class="callout quaternary">

2022: Platform engineering first appears on the Gartner Hype Cycle

2023: Gartner predicts 80% of large engineering orgs will have platform teams by 2026

2024: Platform engineering gets **its own dedicated Gartner Hype Cycle**

</div>

*Something is clearly happening. But what, exactly?*

---

<style scoped>section{font-size:32px;}</style>

# What the Data Actually Says

<div class="callout primary">

**Puppet State of DevOps 2024** — titled *"The Evolution of Platform Engineering"*

Platform engineering is not a trend that **replaces** DevOps — it works **alongside** DevOps goals.
43% of respondents have had a platform team for 3–5 years already.

</div>
<br />
<div class="callout secondary" style="margin-top:0.4rem">

**DORA 2024** — surveyed 39,000+ professionals

Platform engineering's key success factor: *user-centricity* — understanding what
internal developers need and designing tools that meet those needs.

</div>

<small class="muted">Sources: Puppet State of DevOps 2024 · DORA Accelerate State of DevOps 2024</small>

---

# Not Death. Realignment.

DevOps gave us the *principles*. Platform engineering gives them *structure*.

| DevOps Principle | Platform Engineering Expression |
|---|---|
| Automate everything | Self-service golden paths |
| Break down silos | Platform team as internal product team |
| Continuous feedback | KPIs, user journeys, capability maps |
| You build it, you run it | Developer autonomy through paved roads |

<small class="muted">60.9% of organisations apply platform engineering as a **natural evolution** of DevOps, not a replacement — Techstrong Research 2024</small>

---

# One question. Three instruments. One action.

By the end of this session you will have:

- A **diagnostic test** you can apply to your platform this week
- **Three structured tools** that address the root causes of platform failure
- A **specific next action** you can take before the month is out

<small class="muted">Based on: *Platform Engineering for Architects* — Körbächer, Grabner, Lipsig (Packt, 2024)</small>

---

# Act 1
## The Diagnostic

---

# "That's a crock of shit."

> Chamath Palihapitiya, on Bill Gates's reaction to Facebook Platform

Gates said something along the lines of:

> *"This isn't a platform. A platform is when the **economic value of everybody that uses it** exceeds the value of the company that creates it."*

<small class="muted">Source: The Bill Gates Line — Ben Thompson, Stratechery (2018)</small>

---

# The Bill Gates Line

<div class="callout tertiary">

### Above the line
Windows · AWS · Azure — the ecosystem is **larger** than the creator

</div>
<br />
<div class="callout quaternary" style="margin-top:0.4rem">

### Below the line
Platforms that solve the **builder's problems** while treating users as secondary

</div>

---

# Translating the Line for Internal Platforms

| External | Internal Platform Equivalent |
|---|---|
| Economic value to ecosystem | **Developer autonomy and productivity unlocked** |
| Ecosystem larger than creator | **More developer hours saved than platform hours spent** |
| Voluntary external adoption | **Voluntary internal adoption — no mandates needed** |

The question is the same: *who is getting more out of this?*

---

# An Honest Question

<div class="callout gradient">

### Show of hands

*Do your customers get more value from your platform than your team spends building and operating it?*

</div>

<br />
<div class="callout gradient">

### Ask yourself

*Do we even have an engineered __platform__*.

---

# Act 2
## The Root Causes

---

# Meet Platform Team Zeta

- Six engineers · Two years of work · Kubernetes-based IDP
- Technically excellent
- **Adoption: low**

Nobody is filing bugs. Nobody is asking for features.<br/>Developers are routing around the platform.

*Sound familiar?*

---

# Root Cause 1: No Shared Purpose

Zeta has a mission statement on a Confluence page.

Nobody reads it. Nobody could write it from memory.

<div class="callout primary">

The platform team builds what they find **interesting** — not what developers need.

There is no test for when the platform is *winning*.

</div>

---

# Root Cause 2: No User Model

Zeta's last developer survey was **14 months ago**.

Their "golden path" is the path that was easiest for the *platform team* to build.

<div class="callout secondary">

Nobody has sat with a developer and watched them use the platform from scratch.

The platform team's mental model of how developers work is **fiction**.

</div>

---

# Root Cause 3: No Capability Contract

Zeta's platform has **23 capabilities**.

Eleven are documented. The other twelve generate a constant stream of Slack messages.

<div class="callout tertiary">

The platform's surface area is *implicit*.

Nobody knows what is owned, what is supported, or what breaks if something changes.

</div>

---

# Zeta Is Not a Platform. Zeta Is an Aggregator.

Zeta solves the platform team's own operational preferences first.

Developers are an **Nth priority**.

> This is the aggregator trap — building for yourself while *calling it a service*.

**The fix is not more engineering. The fix is product design.**

---

# Act 3
## The Instruments

*Three tools. Three root causes. One feedback loop.*

---

# The Three Instruments

| Instrument | Root Cause It Fixes | Question It Answers |
|---|---|---|
| **Purpose Canvas** | No shared purpose | *Why does this platform exist?* |
| **Journey Map** | No user model | *What does a developer actually need?* |
| **Architecture Workshop** | No capability contract | *How does the platform deliver it?* |

<small class="muted">Max Körbächer — *Platform Engineering for Architects* (Packt, 2024) · Miro templates linked in resources</small>

---

# Instrument 1: The Purpose Canvas

*Fixes Root Cause 1 — before the first infrastructure decision is made*

<div class="callout primary">

**Mission statement** — one sentence, falsifiable, survives leadership change

**User personas** — named, with jobs-to-be-done and current pain. Not just "developer"

**Target KPIs** — outcome-based: *mean time to production*, not *deployments per day*

**Explicit out-of-scope** — what the platform deliberately does not own

</div>

---

# Meet Platform Team GoldPath

- Six engineers · Two years of work · Kubernetes-based IDP
- Same starting point as Zeta
- **They ran the three conversations Zeta never had**

Same engineers. Same stack. Same org size.

*Different question: what would it take to cross the line?*

---
<style scoped>section{font-size:32px;}</style>

# GoldPath vs. Zeta: Mission Statement

<div class="callout quaternary">

### Zeta's mission
*"Provide a standardised Kubernetes platform for engineering teams"*

</div>
<br />
<div class="callout primary" style="margin-top:0.4rem">

### GoldPath's mission
*"Enable any product team to deploy a change to production in under 10 minutes — without raising a platform ticket"*

</div>

**Which team knows when they are winning?**

---

<style scoped>section{font-size:30px;}</style>

<!-- Slide: Instrument 2 - Journey Map — maps to LO "Map" -->

# Instrument 2: The Developer Journey Map

*Fixes Root Cause 2 — validates the golden path from the developer's perspective*

```
Onboarding → Provision → Build → Deploy → Observe → Operate
```

At each stage:
- What does the developer need the platform to do?
- What does the platform currently provide?
- Where does the developer leave the platform — or raise a ticket?

*Every gap is a candidate for the capability backlog.*

---
<style scoped>section{font-size:30px;}</style>

# Classifying the Gaps

| Status | Meaning | Colour |
|---|---|---|
| ✅ **Present** | Capability exists and works | Green |
| ❌ **Missing** | Capability absent or broken | Red |
| ⏸ **Deferred** | Intentionally not built yet | Grey |

**The decision frame at each gap:**

> Build · Buy · Configure · *Deliberately defer*

Gaps blocking a KPI from the Purpose Canvas are **P0**.<br/>Gaps unconnected to any KPI are deferred.

---

<style scoped>section{font-size:30px;}</style>

# Instrument 3: The Architecture Workshop Canvas

*Fixes Root Cause 3 — makes the capability contract explicit and architectural*

<div class="callout tertiary">

**Phase A — Principles** · The guardrails that constrain every decision that follows

**Phase B — Reference Architecture** · What capability categories exist and how they relate *(stable, strategic)*

**Phase C — Target Architecture** · Which specific services implement each capability *(evolving, tactical)*

**Phase D — Control Flow** · The dependency map. Where invisible risk lives.

</div>

---

# Why Phase D Changes Everything

Most teams have a reference architecture diagram.

Few teams have a **control flow map**.

<div class="callout gradient">

Phase D answers: *"What breaks if this component fails?"*

It surfaces the single points of failure that no reference architecture shows you.

**If your platform has no control flow map, you are flying blind.**

</div>

---

# The Feedback Loop

```
Purpose Canvas KPIs
        ↓
  Journey Map gaps
        ↓
Architecture Workshop decisions
        ↓
  Updated capability map
        ↓
  KPI review (90 days)
        ↓
  ← Canvas re-run if KPI drifts
```

*This is not a one-time workshop. It is the operating rhythm of a platform product team.*

---

# What Changed for GoldPath

- Developers file **fewer tickets** — the golden path actually works
- **Adoption is up** — voluntarily, without mandates
- The platform team spends less time **firefighting** and more time **building**
- Every architectural decision traces back to a **KPI in the Purpose Canvas**

GoldPath is **above the Bill Gates Line**.

Not because they hired more engineers.<br/>Because they had three conversations Zeta never had.

---

<!-- ═══════════════════════════════════════════════════════ ACT 4 ══ -->

# Act 4
## The Practice

---

# You Do Not Need All Three at Once

Start where the pain is loudest.

| If your team's biggest problem is… | Start with… |
|---|---|
| No one agrees why the platform exists | **Purpose Canvas** |
| Developers route around the platform | **Journey Map** |
| Nobody knows what the platform owns | **Architecture Workshop** |

*The canvas that answers the question your team is most wrong about right now — that is your next action.*

---

# Your Next Action

<div class="callout gradient">

**60 seconds. Eyes down if it helps.**

*Which root cause is most acute for my platform right now?*

*Which instrument addresses it?*

*What is the first meeting I would call?*

</div>

---

<style scoped>section{font-size:28px;}</style>

# Resources

**Miro Templates** *(free, no account required to preview)*
- Purpose Canvas: `miro.com/miroverse/platform-engineering-purpose-canvas-template/`
- Architecture Workshop: `miro.com/templates/platform-architecture-workshop/`

**The Book**
- *Platform Engineering for Architects* — Körbächer, Grabner, Lipsig (Packt, 2024)
- `a.co/d/1GTowLB`

**The Concept**
- The Bill Gates Line — Ben Thompson, Stratechery (2018)
- `stratechery.com/2018/the-bill-gates-line/`


---

<style scoped>section{font-size:30px;}</style>


# The Canvases Are the Manifest

If your platform were a PowerShell module —

- would it have a **`.psd1` manifest**?
- would **`Install-Module`** work?
- would `CmdletsToExport` list what you actually support?

<br />
<div class="callout primary">

The Purpose Canvas, the Journey Map, and the Architecture Workshop **are the manifest**.

Without them, you have a DLL nobody can install.

*Zeta was below the line. GoldPath crossed it. So can you.*

</div>

---

<!-- _class: title -->

# Questions

<p class="name">Ryan Coates</p>
<p class="handle">https://rdc.dev</p>

<small class="muted">Slides + resources: https://rdc.dev/summit</small>

