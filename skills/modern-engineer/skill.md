---
name: modern-engineer
description: 5-phase compound engineering workflow. Always start at Phase 1 (brainstorm) when asked to build anything. Phases: brainstorm → plan → work → review → debug. Never skip to coding without interviewing first.
---

# /modern-engineer

## Auto-trigger rule
**Whenever the user asks to build, create, or start a new project — always begin at Phase 1.**
Do not skip brainstorming even if the request seems simple or well-defined.

---

## Phase 1 — BRAINSTORM

**Goal:** Understand what's actually needed before writing a line of code.

1. Interview the user with 3-5 targeted questions:
   - Who is this for? *(default assumption: user only)*
   - What specific problem does it solve?
   - What does "done" look like? What's the success condition?
   - What are the must-haves vs nice-to-haves?
   - Any constraints? (existing stack, time, dependencies)

2. Propose **2-3 feature sets** ranked by simplicity — simplest first
3. Confirm direction before proceeding

**Do not proceed to Phase 2 without user confirmation.**

---

## Phase 2 — PLAN

**Goal:** A concrete, agreed-upon implementation plan before touching code.

1. Write the plan:
   - Files to create or modify (with paths)
   - Order of operations
   - Key decisions and why the simple path was chosen
   - Dependencies to install

2. **Bias toward simplest solution** at every decision point
3. **Assume single user** unless told otherwise — no auth, no multi-tenancy, no over-engineering
4. Present plan, get approval

**Do not proceed to Phase 3 without user approval.**

---

## Phase 3 — WORK

**Goal:** Build what was planned. Verify it actually works.

1. Execute the plan step by step
2. After building: **run and test the golden path** — the core thing it's supposed to do
3. Test at least one edge case
4. **Do not report "done" until verified working in the real app**
5. If verification fails: fix it before reporting

---

## Phase 4 — REVIEW

**Goal:** Independent code review as if you didn't write it.

1. Check against the agreed plan — did we build what was approved?
2. Look for: bugs, edge cases, security issues, performance problems
3. Look for: unnecessary complexity, repeated code, things that can be simplified
4. **Explain findings in plain language**

Report format:
```
🔴 Critical — [issue: what breaks and when]
🟡 Should fix — [issue: not critical but causes problems]
🟢 Nice to have — [cleanup or improvement, optional]
```

---

## Phase 5 — DEBUG

**Goal:** Fix the issues found in Phase 4.

1. Fix 🔴 Critical issues first
2. Fix 🟡 Should fix issues
3. Ask before spending time on 🟢 Nice to have items
4. Re-run verification after each significant fix
5. Confirm everything is clean before closing the task

---

## Phase flow summary

```
User: "build X"
    ↓
Phase 1: BRAINSTORM — interview → confirm features
    ↓
Phase 2: PLAN — write plan → get approval
    ↓
Phase 3: WORK — build → verify it runs
    ↓
Phase 4: REVIEW — independent audit → flag issues
    ↓
Phase 5: DEBUG — fix issues → re-verify → done
```
