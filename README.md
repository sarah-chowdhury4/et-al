# Et Al.

**A research team room where three AI agents, running on two different models, work alongside the people doing the research, and the PI signs off on every step.**

Et Al. is a [Switch](https://github.com/sandbox-quantum/switch) room that follows a real thesis workflow: idea, literature, methodology, experiments, verification. A scout finds and digs into papers, a coordinator keeps the project planned and on record, and an experimenter turns the agreed methodology into checked results. No experiment runs until the PI replies "Approved".

![The research room](docs/room.png)

**Demo video:** VIDEO-LINK

Built for the Flip the Switch hackathon (WeMakeDevs x DevTools Academy x Switch), Best Business Workflow track.

## Contents

- [Getting started](#getting-started)
- [Running the demo](#running-the-demo)
- [How it works](#how-it-works)
- [How Switch is used](#how-switch-is-used)
- [Results](#results)
- [Project structure](#project-structure)
- [Troubleshooting](#troubleshooting)
- [Limitations](#limitations)

## Getting started

Setup takes about an hour, most of it waiting for installs. It works on Windows, macOS and Linux. Where commands differ, both versions are given: **Windows** commands run in PowerShell 7 (`pwsh`, not the older Windows PowerShell), and **macOS / Linux** commands run in bash or zsh. The two setup scripts come in both forms: `.ps1` for Windows and `.sh` for macOS and Linux.

### Prerequisites

| Tool | Used for | Check |
| --- | --- | --- |
| [Git](https://git-scm.com/) | Cloning the repo | `git --version` |
| [Docker](https://docs.docker.com/get-docker/): Docker Desktop or Rancher Desktop on Windows (no WSL needed) and macOS, Docker Engine on Linux | The local Switch server | `docker run hello-world` |
| [Node.js LTS](https://nodejs.org/) | `npx`, required by Switch | `npx -v` |
| [Python 3.10+](https://www.python.org/) | The experiments | `python --version` (Windows), `python3 --version` (macOS / Linux) |
| [PowerShell 7](https://learn.microsoft.com/powershell/scripting/install/installing-powershell) (Windows only) | The setup scripts | `pwsh --version` |
| [Switch Console](https://docs.switchagents.ai/switch-rooms/getting-started/install-switch-console.md) | Running the Switch server and agents | Opens with the **Setting up Switch** checklist in the sidebar |
| [Claude Code](https://docs.anthropic.com/en/docs/claude-code), signed in | The experimenter agent | `claude --version` |
| [Cursor CLI](https://cursor.com/cli), signed in, with a Grok model | The coordinator and scout agents | `cursor-agent --version` |

Platform notes:

- **Windows:** install PowerShell 7 with `winget install Microsoft.PowerShell`. Windows ships only the older Windows PowerShell 5.1. Install Switch Console with the `.exe` installer (or the `.msi`); the Windows build is early access.
- **macOS:** with [Homebrew](https://brew.sh/), `brew install git node python` covers Git, Node.js and Python. Install Docker Desktop or Rancher Desktop separately. Install Switch Console from the `.dmg` (Apple silicon or Intel) by dragging it into Applications. The macOS build is Switch's stable release.
- **Linux (Debian / Ubuntu):** `sudo apt install git python3 python3-venv docker.io docker-compose-v2`, then `sudo usermod -aG docker $USER` and log out and back in so Docker runs without `sudo`. Install Node.js LTS from nodejs.org. Install Switch Console from the `.deb` with `sudo apt install ./switch-console-amd64.deb` (use `apt`, not `dpkg -i`, so dependencies resolve; the AppImage needs FUSE 2, which Ubuntu 24.04 and later can block). The Linux build is early access.

The project can live anywhere, as long as the folder's path has no spaces; agents can trip over paths with spaces. The rest of this guide calls that folder the *project folder*.

### 1. Clone the repo and create the Python environment

Create a project folder in any location and clone the repo into it. The Python environment goes in the same folder, next to the repo, which is where the setup scripts look for it by default. The commands below create a folder called `research` in the current directory; any name and location work.

**Windows:**

```powershell
mkdir research
cd research
git clone https://github.com/GITHUB-USERNAME/et-al.git
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install torch --index-url https://download.pytorch.org/whl/cpu
pip install scikit-learn numpy matplotlib
cd et-al
```

If `Activate.ps1` reports that running scripts is disabled, run `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` and try again.

**macOS / Linux:**

```bash
mkdir research
cd research
git clone https://github.com/GITHUB-USERNAME/et-al.git
python3 -m venv .venv
source .venv/bin/activate
pip install torch --index-url https://download.pytorch.org/whl/cpu   # on macOS: pip install torch
pip install scikit-learn numpy matplotlib
cd et-al
```

### 2. Start Switch

1. **Start Docker** and wait until `docker ps` works: open Docker Desktop or Rancher Desktop (Windows, macOS), or on Linux run `sudo systemctl start docker`.
2. **Sign in to both agent providers** outside Switch Console:
   - Claude Code: `claude auth login`
   - Cursor CLI: sign in as described in [Cursor's CLI docs](https://cursor.com/cli)
3. **Open Switch Console** and go to **Settings → Agent providers**. The status line under both **Claude Code** and **Cursor** must read **Signed in**. The **Installed** badge alone isn't enough. After signing in, select **Recheck**. If a provider still shows **CLI not installed**, fully quit Switch Console and reopen it, since it reads `PATH` only at startup. To fully quit: **Cmd+Q** on macOS, close the window on Windows, `pkill -x switch-console` on Linux.
4. **Add a server.** In the **Setting up Switch** checklist in the sidebar, choose **Add a server**, then **Run a server on this computer**, and start it. The first start downloads several GB. The server keeps running when Switch Console quits, but it doesn't restart after the computer restarts; open Switch Console to start it again.
5. **Sign in to Mattermost.** On the server's **Home** page, under **Messaging apps**, select **Sign-in details…** on the Mattermost row. It shows the address, username and password of the Mattermost account Switch created for you, and Switch links that account to you automatically. This account is the PI.

### 3. Create the student account

The demo has two people: a PI and a student. The PI is the Mattermost account from **Sign-in details…** in step 2. Note its username; on a local server it is `user`. Agents identify senders by username, not display name.

To add the student:

1. Open Mattermost from Switch Console.
2. In the main menu, choose **Invite People** and copy the invite link.
3. Open the link in a private browser window and sign up. Note the username.

### 4. Fill in local settings

**Windows:**

```powershell
.\scripts\fill-local.ps1
```

**macOS / Linux:**

```bash
bash scripts/fill-local.sh
```

The script asks four questions:

| Question | Answer |
| --- | --- |
| PI Mattermost username | The username from **Sign-in details…** (`user` on a local server) |
| Student Mattermost username | The username from step 3 |
| Email for OpenAlex | Any email you own. OpenAlex asks API users for one. |
| Path to the experimenter's Python | Press Enter to accept the default: the `.venv` in the project folder (`.venv\Scripts\python.exe` on Windows, `.venv/bin/python` on macOS and Linux) |

It writes filled copies of the agent instructions, the room instructions and the Switch template to `local/`. Git ignores that folder, so usernames and email never reach the repo. Paste and import from `local/`, never from the placeholder files in `agents/`, `room/` or `templates/`. Answers are saved in `local/answers.json`, so later runs only need Enter.

Then check everything:

**Windows:**

```powershell
.\scripts\check-setup.ps1
```

**macOS / Linux:**

```bash
bash scripts/check-setup.sh
```

Fix any line marked `FAIL`, from the top down, and run it again until it passes.

### 5. Create the agents and the room

Choose one of the two options below.

#### Option A: Import the template

1. In Switch Console, open **Templates**, select **Import template**, and supply `local/templates/et-al.template.yaml`.
2. On the **Templates** page, select **Use** on the imported template, fill in the fields, and select **Create all**. This creates the three agents, the `research-room` room with both people in it, and the room instructions.
3. Open the coordinator and the scout under **Your Agents** and set a Grok model in the **Model** field of **Advanced configuration**.

Requirements: the agent names must be free (remove any existing `coordinator`, `scout` or `experimenter` first), both providers must be signed in, and the server must have agent management turned on. If the run reports that agent management is off, use Option B.

#### Option B: Set it up by hand

In Switch Console, open **Your Agents** in the sidebar and select the dashed card with a plus to onboard each agent:

| Field | coordinator | scout | experimenter |
| --- | --- | --- | --- |
| Name | `coordinator` | `scout` | `experimenter` |
| Description | Plans the project and keeps its documents | Finds and digs into research papers | Writes, runs, and debugs experiments following the methodology |
| Agent instructions | `local/agents/coordinator.md` | `local/agents/scout.md` | `local/agents/experimenter.md` |
| Run location | This computer | This computer | This computer |
| Directory | `<project folder>/et-al/workspace/coordinator` | `<project folder>/et-al/workspace/scout` | `<project folder>/et-al/workspace/experimenter` |
| Agent provider | Cursor | Cursor | Claude Code |
| Advanced configuration → Model | A Grok model | A Grok model | `sonnet` |
| Advanced configuration → Disallowed tools | (leave empty) | (leave empty) | `WebFetch, WebSearch` |

Name, run location and directory can't be changed after the agent is created.

For all three agents, under **Settings** in the same form:

| Setting | Value | Why |
| --- | --- | --- |
| Bypass permissions | On | Off by default on this computer. Without it, agents stop at permission prompts nobody in the room can see. |
| Who can talk to your agent | Anyone | The default, **Me and my agents**, ignores the student account. **Anyone** includes people in the agent's rooms without a Switch account. |
| Can manage agents | Off | Not needed; it lets an agent create agents on your machines. |

Select **Add agent** to create each one. If you change **Bypass permissions** later, stop and restart the agent's session for it to take effect.

Use the full path for each directory. To print the full path of the `workspace` folder, run `(Resolve-Path workspace).Path` (Windows) or `echo "$(pwd)/workspace"` (macOS / Linux) from the `et-al` folder.

Copy an instructions file to the clipboard with:

| System | Command |
| --- | --- |
| Windows | `Get-Content .\local\agents\coordinator.md -Raw \| Set-Clipboard` |
| macOS | `pbcopy < local/agents/coordinator.md` |
| Linux | `xclip -selection clipboard < local/agents/coordinator.md` (or `wl-copy < local/agents/coordinator.md` on Wayland) |

Then, in Switch Console, select **Your Rooms**, then **Create room**:

| Field | Value |
| --- | --- |
| Messaging app | Mattermost |
| Name | `research-room` |
| Description | Research team room: PI, student, coordinator, scout and experimenter agents. |
| Agents | coordinator, scout, experimenter |
| Instructions | Contents of `local/room/instructions.md` |

Fill in the description; room creation can fail without one.

The room appears as a Mattermost channel. People join a room by joining its channel: in Mattermost, open the `research-room` channel and add the student account (and the PI account, if it isn't already a member) with **Add members**. Switch adds channel members to the room. An agent left out of the form can be added from the channel with `!invite-agent @agent-name`.

### 6. Check the agents respond

As the student, post:

```
@coordinator reply with one word: ready
```

Repeat for `@scout` and `@experimenter`. Each should answer in the room within a minute. To see every agent's state at once, post `!agents-status` as its own message: 🟢 live, no marker dormant (wakes when mentioned), ⚪ no session, 🔴 disconnected, ✋ waiting on a permission request. If an agent doesn't answer, see [Troubleshooting](#troubleshooting).

## Running the demo

Use a fresh room for each run, set up the same way as `research-room`, so earlier messages don't confuse the agents. Open the PI and student in two browser windows side by side. The full script, with what to wait for at each step, is in [`demo/script.md`](demo/script.md).

| Step | Who | Message |
| --- | --- | --- |
| 1. Idea | PI | `@coordinator New project: does label smoothing help a small network trained on noisy labels? Target is a workshop paper, deadline Dec 1. Please set up a plan.` |
| 2. Foundations | — | Wait for the scout's Literature list |
| 3. Dig | PI | `@scout dig 3`, then `@scout summary 3` |
| 4. Methodology | PI | `@coordinator Approved.` |
| 5. Baseline | Student | `@experimenter Can you set up a baseline following the Methodology?` |
| 6. The gate | Student, then PI | `@experimenter Approved.` (refused for the student), then the same from the PI |
| 7. Results | — | Wait for the 3-seed table |
| 8. Record | — | Wait for the coordinator's log update |

The longest waits are the scout reading paper records and the experimenter running code.

### Paper commands

Anyone in the room can use these. `N` is a paper number from the Literature document.

| Command | What it does |
| --- | --- |
| `@scout summary N` | 3 to 4 sentences from the abstract: problem, method, main finding |
| `@scout rate N` | Relevance to the research question, 1 to 5, labelled as a judgment |
| `@scout dig N` | Adds the 5 most relevant papers from paper N's references to Literature |

### Viewing the documents

The agents keep five documents: Timeline, Literature, Methodology, Decisions log and Lab notebook. They are stored in the room and also written as Markdown files in `workspace/coordinator/` and `workspace/scout/`. Post `!list-documents` in the room to list the room's documents. To read one in the chat, ask the agent that keeps it:

```
@coordinator paste the Timeline document here.
```

## How it works

Five members share one room: two people and three agents.

| Member | Runs on | Role |
| --- | --- | --- |
| PI | Person | Sets the question and deadline, digs into papers, approves the methodology and every experiment |
| Student | Person | Requests experiments and follows up on tasks |
| `@coordinator` | Cursor + Grok | Writes the Timeline, drafts the Methodology, keeps the Decisions log and Lab notebook |
| `@scout` | Cursor + Grok | Finds foundation papers grouped by theory and answers paper commands. Every paper comes from [OpenAlex](https://openalex.org/), never from model memory |
| `@experimenter` | Claude Code + Sonnet | Writes, runs and debugs experiments that follow the Methodology. Never runs one without the PI's approval |

The workflow:

1. **Idea.** The PI posts a research question and a deadline. The coordinator restates the question, writes a Timeline of 4 to 6 tasks with owners and due dates, and asks the scout for papers.
2. **Foundations.** The scout breaks the idea into the 3 to 4 theories it rests on and lists about 10 foundational papers, numbered, with citation counts and OpenAlex links.
3. **Methodology.** The coordinator drafts the hypothesis, data, model, metric, baseline, comparison and number of seeds. The PI approves it, and the approval goes into the Decisions log.
4. **Baseline.** The student asks for a baseline. The experimenter writes `baseline.py`, runs it, fixes its own errors, and reports the test accuracy.
5. **The gate.** The experimenter proposes the comparison and waits. It checks the sender of every "Approved" against the PI named in the room instructions, so the student's approval is refused.
6. **Results.** After the PI approves, the experimenter runs `ablation.py` with 3 seeds per setting and posts a table, with a line confirming it followed the Methodology.
7. **Record.** The coordinator logs the result, marks tasks done, adds a dated Lab notebook entry, and names the next milestone.

The demo question: does label smoothing help a small network trained on noisy labels? It uses scikit-learn's digits dataset with 20% of training labels flipped to a wrong class, a small PyTorch network, and a clean test set. Each script runs on a CPU in under a minute.

## How Switch is used

Et Al. depends on Switch to turn three separate coding agents into teammates in one shared room.

- **One room for people and agents.** The PI, the student and all three agents share a single Switch room, mirrored into Mattermost. Everyone sees the same conversation and the same record.
- **Agents as teammates.** Each agent is onboarded in Switch Console with its own working directory, provider, instructions and permissions, and responds only when mentioned by name.
- **Any agent, any model.** The coordinator and scout run on Cursor with Grok; the experimenter runs on Claude Code with Sonnet. Switch puts them in the same room without either needing to know what the other runs on.
- **Handoffs by mention.** The coordinator asks `@scout` for papers, the scout tells `@coordinator` they're ready, and the experimenter tells `@coordinator` when results are in. There is no orchestration code: agents address each other in the room.
- **Room instructions.** The room tells every agent who the PI and the student are. The experimenter uses this to refuse approvals from anyone but the PI.
- **Room documents.** Timeline, Literature, Methodology, Decisions log and Lab notebook are stored in the room, next to the conversation that produced them.
- **Templates.** [`templates/et-al.template.yaml`](templates/et-al.template.yaml) creates all three agents and the room in a single import.

## Results

From one demo run: 3 seeds per setting, 20% label noise, clean test set.

RESULTS-TABLE

The scripts the experimenter wrote are in [`workspace/experimenter/`](workspace/experimenter/). The documents from the same run are in [`workspace/coordinator/`](workspace/coordinator/) and [`workspace/scout/`](workspace/scout/).

To rerun the experiments without any agent, from the `et-al` folder:

**Windows:**

```powershell
cd workspace\experimenter
..\..\..\.venv\Scripts\python.exe baseline.py
..\..\..\.venv\Scripts\python.exe ablation.py
```

**macOS / Linux:**

```bash
cd workspace/experimenter
../../../.venv/bin/python baseline.py
../../../.venv/bin/python ablation.py
```

## Project structure

```
et-al/
├── agents/                  Instructions for each agent (with placeholders)
│   ├── coordinator.md
│   ├── scout.md
│   └── experimenter.md
├── room/
│   └── instructions.md      The room's instructions (with placeholders)
├── templates/
│   └── et-al.template.yaml  Switch template: three agents and the room
├── scripts/
│   ├── fill-local.ps1       Fills in usernames, email and paths; writes local/ (Windows)
│   ├── fill-local.sh        The same, for macOS and Linux
│   ├── check-setup.ps1      Checks tools, repo, Python, filled files and network (Windows)
│   └── check-setup.sh       The same, for macOS and Linux
├── workspace/               Each agent's working directory
│   ├── coordinator/         Timeline, Methodology, Decisions log, Lab notebook
│   ├── scout/               Literature
│   └── experimenter/        baseline.py, ablation.py
├── demo/
│   └── script.md            The demo, message by message
├── docs/                    Screenshots and build notes
└── local/                   Filled copies (git-ignored, created by the fill-local script)
```

To change an agent's behavior, edit its file in `agents/`, run the fill-local script again, and paste the new copy from `local/agents/` into the agent's instructions in Switch Console. Switch keeps agent settings outside the repo, so the files in `agents/` and `room/` are the source of truth.

## Troubleshooting

| Problem | Fix |
| --- | --- |
| An agent doesn't reply to a mention | Post `!agents-status` to see its state. Check the thread under your message, since replies often land there. Mention the agent by its exact name, and don't end the sentence right after the name: a trailing period becomes part of it |
| "You're not permitted to direct messages to me in this room" | Set **Who can talk to your agent** to **Anyone** in the agent's settings |
| "I'm not online in this room" | Open Switch Console on the computer that runs the agent. Agents run by Switch Console stop answering when it quits |
| ✋ in `!agents-status`, or the agent goes silent mid-task | It's waiting on a permission request. Answer it in the room, or turn on **Bypass permissions** and restart the agent's session |
| A session never starts | The provider is likely waiting on a folder-trust prompt. Make sure **Settings → General → Auto-trust worktree directories** is on |
| The PI's "Approved" is refused | The room instructions must name the PI by Mattermost username. The account Switch Console creates is `user`, not its display name. Run the fill-local script again with `user` as the PI and paste the new room instructions |
| An agent receives messages but can't post or read the room, or reports that its Switch connection is down | Fully quit and reopen Switch Console (this also helps after a network change such as a VPN reconnect), then post `!reset @agent-name` in the room and mention the agent again. If that fails, remove the agent and onboard it again |
| A provider shows **CLI not installed** after installing it | Fully quit and reopen Switch Console, which reads `PATH` only at startup: **Cmd+Q** on macOS, close the window on Windows, `pkill -x switch-console` on Linux |
| The experimenter fails with "module not found" | It's using the wrong Python. Check the path in `local/agents/experimenter.md` and run the check-setup script |
| A paper link doesn't open or doesn't match its title | The scout answered from memory. Restart its session and repeat the request; its instructions require OpenAlex links only |
| Room creation fails | Fill in the room description. If **Create room** doesn't respond, sign in to the server first |
| Docker or the local server won't start | Start Docker (Docker Desktop or Rancher Desktop, or `sudo systemctl start docker` on Linux) and wait until `docker ps` works, then restart Switch Console. After a computer restart, open Switch Console to start the server again |
| `docker` needs `sudo` on Linux | Add yourself to the `docker` group with `sudo usermod -aG docker $USER`, then log out and back in (reboot if `id` still doesn't list the group) |
| No Switch Console window on Linux | Common under Wayland, often in a VM. See the [Switch troubleshooting page](https://docs.switchagents.ai/switch-rooms/resources/troubleshooting.md) |
| `fill-local.ps1` won't run on Windows | Run `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` in PowerShell 7 |

## Limitations

- The approval gate is enforced by agent instructions and the room's record of who the PI is, not by a permission system. It held in testing, but it's a convention the agent follows, not a lock.
- `rate` is the scout's judgment, not a measurement, and it says so.
- The scout reads abstracts and reference lists, not full papers.
- The demo experiment is deliberately small. A real lab would point the experimenter at its own datasets and compute.
- Built and tested end to end on Windows with Switch Console's early-access Windows build. The macOS and Linux steps use the same tools, and the bash setup scripts produce the same files as the PowerShell ones, but a full demo run hasn't been tested on those systems.
