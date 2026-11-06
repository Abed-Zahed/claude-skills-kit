---
name: modern-engineer
description: "5-phase compound engineering workflow. Always start at Phase 1 (brainstorm) when asked to build anything. Phases: brainstorm -> plan -> work -> review -> debug. Never skip to coding without interviewing first."
---

# /modern-engineer

## Tutorial mode

- Runs when the user types `/modern-engineer tutorial`, or asks to learn the skill.
- First run only: if `.tutorial_offered` does not exist in this skill folder, ask once "Want a short guided tutorial for /modern-engineer? (yes / no)" before the setup check, then create that file so it is never asked again.
- On yes: read `TUTORIAL.md` in this skill folder and walk the user through it one step at a time, waiting for them after each step. Then return to their original request, if any.

## Auto-trigger rule
**Whenever the user asks to build, create, or start a new project, always begin at Phase 1.**
Do not skip brainstorming even if the request seems simple or well-defined.

---

## Phase 1, BRAINSTORM

**Goal:** Understand what's actually needed before writing a line of code.

1. Interview the user with 3-5 targeted questions:
   - Who is this for? *(default assumption: user only)*
   - What specific problem does it solve?
   - What does "done" look like? What's the success condition?
   - What are the must-haves vs nice-to-haves?
   - Any constraints? (existing stack, time, dependencies)

2. Propose **2-3 feature sets** ranked by simplicity, simplest first
3. Confirm direction before proceeding

**Do not proceed to Phase 2 without user confirmation.**

---

## Phase 2, PLAN

**Goal:** A concrete, agreed-upon implementation plan before touching code.

1. Write the plan:
   - Files to create or modify (with paths)
   - Order of operations
   - Key decisions and why the simple path was chosen
   - Dependencies to install

2. **Bias toward simplest solution** at every decision point
3. **Assume single user** unless told otherwise, no auth, no multi-tenancy, no over-engineering
4. Present plan, get approval

**Do not proceed to Phase 3 without user approval.**

**The moment the plan is approved, before any Phase 3 work starts, write it verbatim to a durable file** in the relevant repo (a `PLAN.md`/`REWRITE_PLAN.md` next to the code it governs, or a full entry in `SESSION_HISTORY.md`), with a checklist to tick as stages land. A plan that exists only as chat text is exactly what a later `/compact` silently drops, a decision stated once and never repeated has nothing anchoring it into a summary. This applies even to a single-message plan, not just multi-session ones.

---

## Phase 3, WORK

**Goal:** Build what was planned. Verify it actually works.

1. Execute the plan step by step
2. After building: **run and test the golden path**, the core thing it's supposed to do
3. Test at least one edge case
4. **Do not report "done" until verified working in the real app**
5. If verification fails: fix it before reporting

---

## Phase 4, REVIEW

**Goal:** Independent code review as if you didn't write it.

Approach this phase as a **separate reviewer** who is seeing the code fresh:

1. Check against the agreed plan, did we build what was approved?
2. Look for: bugs, edge cases, security issues, performance problems
3. Look for: unnecessary complexity, repeated code, things that can be simplified
4. **Explain findings in plain language**, no jargon, the user may not be a developer

Report format:
```
🔴 Critical, [issue: what breaks and when]
🟡 Should fix, [issue: not critical but causes problems]
🟢 Nice to have, [cleanup or improvement, optional]
```

---

## Phase 5, DEBUG

**Goal:** Fix the issues found in Phase 4.

1. Fix 🔴 Critical issues first, these block usage
2. Fix 🟡 Should fix issues
3. Ask before spending time on 🟢 Nice to have items
4. Re-run verification after each significant fix
5. Confirm everything is clean before closing the task

---

## Phase flow summary

```
User: "build X"
    ↓
Phase 1: BRAINSTORM, interview → confirm features
    ↓
Phase 2: PLAN, write plan → get approval
    ↓
Phase 3: WORK, build → verify it runs
    ↓
Phase 4: REVIEW, independent audit → flag issues
    ↓
Phase 5: DEBUG, fix issues → re-verify → done
```
