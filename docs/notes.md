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
| Nov 5 | No way to assign room roles (Mattermost has none; Switch roles need an agent to claim them) | Cut 4: agents and people mention each other by name (@coordinator, @scout, @experimenter) |
| Nov 5 | switch-buddy-admin said its connection to Switch was down | Only the buddy was affected; coordinator and scout still answered. Used Claude Code + switch-docs for questions instead |
| Nov 5 | Couldn't find the room documents the agents created | Documents live on the Switch server, not in Mattermost. The native local server (Console 0.31, Windows) ships no web dashboard: http://localhost:<api port>/ only answers "Missing or invalid Authorization header". Ports are in %APPDATA%\switchdash\local-switch-server\ports.json. Workaround: ask the agent to paste the document into the room. Fix (Nov 6): coordinator and scout also save each document as a .md file in their workspace folder, so it can be read, committed and shown to judges |
| Nov 5 | T5: the PI's "Approved" was refused too. The coordinator said it came from "user", not the PI (saraht3ch) | Console creates the main Mattermost account with the username `user`; agents see that username, and "Sarah Chowdhury" is only the display name. Fix: rerun fill-local.ps1 with PI username `user`, paste the new room instructions into a fresh room (research-room-2), rerun T5. Don't rename the main account: Console signs in to Mattermost as `user` |
| Nov 6 | Every Claude Code agent (experimenter, switch-buddy-admin) heard the room but couldn't reply: "invalid response" from the Switch tools on 127.0.0.1:<port>, a new port each session. Cursor/Grok agents fine. Updating Claude Code didn't help | Cause: AVG antivirus Web Shield intercepting Claude Code's HTTP traffic, including loopback. Evidence: `claude mcp list` showed `InvalidHTTPResponse` on every HTTP MCP server while `curl.exe` got a clean 200 from the same URLs and there was no proxy. Fix: turned AVG off and Claude agents replied. Permanent fix: AVG exceptions for claude.exe and for http://127.0.0.1/* and http://localhost/* (or turn off Web Shield's HTTPS scanning) |
|  |  |  |

## Day 1, Nov 4: room, coordinator, scout

- Test runs used (limit 5):
- T1 Idea to Timeline:
- T2 Foundation papers (links checked by hand):
- T3 Silence when not mentioned:
- T4 Methodology draft:
- T5 Only the PI approves: gate works (student's "Approved" refused), but the PI's was refused too because of the username mismatch above. Rerun in research-room-2 after the fix.
- Tagged day1 at:

## Day 2, Nov 5: experimenter, gate, paper commands

- T6 summary:
- T7 rate:
- T8 dig:
- T9 no made-up papers:
- T10 baseline (accuracy): failed on scope, not behavior. The coordinator's Methodology was paper-scale (ResNet-20, CIFAR-10, 2 noise levels x 3 smoothing settings x 5 seeds = 30 runs), so the baseline only reached 32.54% on a cut-down budget. The experimenter followed the Methodology, fixed its own 60 s overrun, and asked the PI how to handle the budget instead of guessing. Fix: the Methodology now has a compute budget field (hardware and time per script, from the PI, or "not given") and is sized to fit it. On its first request in a room, the experimenter detects the machine's specs, asks the requester for a time limit if none is given, and proposes a smaller plan for PI approval if the runs won't fit. The demo's first message states the budget ("under a minute each on my laptop CPU").
- T11 rerun by hand (same number?): pass. 32.54%, same as posted, 18.2 s (the agent's own run took 51.3 s).
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
