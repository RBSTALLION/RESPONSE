# RESPONSE

Guarding and patrol management software for security companies — a modern alternative to SmartTask Static Patrol and similar platforms.

> **Status:** Concept stage. This repo currently holds static mock-ups and planning material only — there is no working build yet.

## Brand

| | |
|---|---|
| Primary | Black |
| Secondary | Silver |
| Accent | Red |

## Repository layout

```
RESPONSE/
├── mockups/        Static HTML/CSS screen mock-ups (one file per screen)
│   ├── web/        Control-room / office dashboard screens
│   └── mobile/     Officer app screens
├── brand/          Logo files, colour tokens, fonts
├── docs/           Feature list, competitor notes, planning
└── README.md
```

## Deploying (live prototype)

`site/` is the deployable prototype, a static site with no build step:

| Route | What it is |
|---|---|
| `/app` | Officer app for phones (installable: Safari, Share, Add to Home Screen) |
| `/portal` | Control room web portal |
| `/` | Both side by side, sharing one live demo state |

To deploy, paste this into Terminal (Mac or Linux):

```bash
curl -fsSL https://raw.githubusercontent.com/RBSTALLION/RESPONSE/main/deploy.sh | bash
```

It needs Node.js 18+ and a Vercel login (the script opens the browser login the first time).
Set `VERCEL_SCOPE=<team-slug>` to deploy under a specific Vercel team, or `TARGET=preview` for a preview URL.
Drag-and-drop still works too: drag the `site/` folder into vercel.com/new.

Live sync: with a Supabase URL and anon key in `site/config.js` (or `SUPABASE_URL` and `SUPABASE_ANON_KEY` set when running the script), the phone app and the portal share one live demo state across devices. Run `supabase/migrations/20261011180000_demo_state.sql` in the Supabase SQL editor first. Without it, demo state stays in each browser.

## Viewing the mock-ups

Open any `.html` file in `mockups/` directly in a browser. No build step is needed.

## Planned areas (to be scoped)

- Officer app: check-ins, patrol checkpoints, incident reports, lone-worker welfare
- Control room: live officer map, missed-check alerts, site and shift overview
- Client portal: patrol reports and incident history per site
