# Build notes

Running log of what broke and how it got fixed. This becomes the blog post.
Add a line the moment something breaks, not at the end of the day.

## Decisions made before the event

- **Coordinator and scout on Cursor with Grok, experimenter on Claude Code (Sonnet).** Two models in one room: Grok for the reading-heavy work, Claude for code.
- **Gemini through OpenCode: ruled out.** Switch Console couldn't find OpenCode on Windows.
- **AWS Bedrock: ruled out.** The account gets AccessDeniedException on Anthropic models.
- **No Tasks or Decisions feature in rooms** (switch-buddy, Nov 1). The coordinator keeps room documents instead: Timeline, Methodology, Decisions log, Lab notebook.
- **Templates can be imported** in Console (Templates, then Import template).
- **Agents hand work to each other** by mentioning one another in the room. No extra setup since one person owns all three.
- **Papers only from OpenAlex**, never from model memory, so every link is real.

## Things to watch (found while preparing the file pack)

- **Roles are leases, not settings.** In Switch, a room role is an instruction bundle an agent picks up with `assume_role`, and the lease ends shortly after that agent's session disconnects. If `@scribe`, `@librarian` or `@runner` get no reply, the agent probably isn't holding the role right now. Fixes, in order: (1) check who holds the role in the room's settings; (2) add one line to that agent's file: "At the start of every session, assume your role in this room with assume_role."; (3) build the room from the template, which uses room **aliases** (`scribe`, `librarian`, `runner`) that always point at the same agent; (4) cut handoff by role and mention agents by name.
- **Template text and braces.** Switch templates read `{name}` as a parameter. Keep `{` and `}` out of the agent files (fill-local.ps1 warns if it sees one).
- **Room description is required.** Room creation fails quietly without it (hit on Nov 1).

## Issue log

| Date | Problem | Fix |
| --- | --- | --- |
| Nov 1 | Room creation failed with no clear error | Added a room description |
| Nov 1 | Console couldn't find OpenCode on Windows | Moved the coordinator off Gemini |
|  |  |  |

## Day 1, Nov 4: room, coordinator, scout

- Test runs used (limit 5):
- T1 Idea to Timeline:
- T2 Foundation papers (links checked by hand):
- T3 Silence when not mentioned:
- T4 Methodology draft:
- T5 Only the PI approves:
- Tagged day1 at:

## Day 2, Nov 5: experimenter, gate, paper commands

- T6 summary:
- T7 rate:
- T8 dig:
- T9 no made-up papers:
- T10 baseline (accuracy):
- T11 rerun by hand (same number?):
- T12 gate waits:
- T13 only the PI's approval counts:
- T14 results table:
- T15 the record:
- Full run 1 glitches:
- Tagged mvp at:

## Day 3, Nov 6: reliability

- Template import (T18):
- Steps I had to guess while rebuilding (each goes into the README):
- Dry run 2:
- Dry run 3:
- Tagged final at:

## Results to paste into the README

```
| setting | mean accuracy | std |
| --- | --- | --- |
```

## Blog outline

1. What I built and why research teams need it
2. How Switch made it work: rooms, agents as teammates, documents, handoffs, two models in one room
3. What broke and how I fixed it (from the issue log)
4. What I'd do next
