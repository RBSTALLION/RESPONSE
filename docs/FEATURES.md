# RESPONSE — Feature list (v0.1, concept)

RESPONSE is guarding and patrol management software for UK security companies. It has three parts:

1. **Officer app** (mobile): what the officer on site uses.
2. **Control room** (web): what the office or control room watches live.
3. **Client portal** (web): what the security company's customers see.

Priorities: **P1** = must have for first release, **P2** = soon after, **P3** = later.

---

## 1. Officer app (mobile)

| Feature | What it does | Priority |
|---|---|---|
| Book on / book off | Officer starts and ends a shift from the app; GPS and time recorded | P1 |
| Patrol checkpoints | Scan NFC tags or QR codes at set points on a patrol route; missed or late points are flagged | P1 |
| Welfare check calls | App prompts the officer at set intervals ("Are you OK?"); no answer escalates to the control room | P1 |
| Panic / SOS button | One press alerts the control room with live location | P1 |
| Incident reports | Guided form with photos, video, voice note, location and time; sent instantly | P1 |
| Site info | Assignment instructions, site contacts, hazards and keyholding notes | P1 |
| Occurrence book (DOB) | Digital daily occurrence log per site, replacing the paper book | P2 |
| Visitor & vehicle log | Log visitors and vehicles in and out, with a photo of the plate | P2 |
| Man-down detection | Phone motion sensor spots a fall or no movement and raises an alert | P2 |
| Offline mode | Everything works without signal and syncs when back online | P2 |
| Policy & training sign-off | Officer reads and confirms company policies and site documents | P3 |

## 2. Control room (web)

| Feature | What it does | Priority |
|---|---|---|
| Live officer map | Every officer on shift shown on a map, with status colours | P1 |
| Alert feed | One live list of missed checkpoints, missed welfare checks, SOS and man-down alerts, with acknowledge and resolve | P1 |
| Shift overview | Who's on, who's late to book on, and which sites are uncovered | P1 |
| Sites & patrol routes | Set up sites, checkpoints (NFC/QR), routes and check-call intervals | P1 |
| Incident management | Review, assign, add notes and close incidents | P1 |
| Reports | Patrol completion %, incidents by site, check-call compliance; export to PDF and CSV | P2 |
| Rota / scheduling | Build shifts, assign officers, and spot clashes and SIA licence expiry | P2 |
| SIA licence tracking | Store licence numbers and expiry dates, with warnings before expiry | P2 |
| Audit trail | Every action logged with time and user | P2 |

## 3. Client portal (web)

| Feature | What it does | Priority |
|---|---|---|
| Site dashboard | Patrols completed, checkpoints hit and incidents this week | P1 |
| Incident history | Read-only view of incident reports with photos | P1 |
| Automatic reports | Daily or weekly patrol report emailed to the client | P2 |
| Service requests | Client requests extra patrols or a guard for an event | P3 |

---

## How RESPONSE should beat SmartTask

SmartTask Static Patrol already covers the basics: book on/off, NFC and iBeacon checkpoints, lone-worker check calls, alerts, e-forms, incident reports, site documents, policy sign-off and automated reports ([source](https://smarttask.co.uk/smarttask-security/static-patrol)). So parity is the entry ticket. The edge has to come from elsewhere:

- **Simplicity and speed.** A modern, fast app officers actually like using, and a control room that's usable on day one without training.
- **Self-serve setup.** A small security firm signs up, adds sites and prints QR checkpoints the same afternoon, with no sales call or install project.
- **Transparent pricing.** Per-officer monthly pricing on the website.
- **Client portal as a selling tool.** Clients see proof of patrols live, which helps the security firm win and keep contracts.

## Open questions

- Target customer first: small firms (5–50 officers) or large contractors?
- NFC, QR, or both at launch?
- Native apps (iOS/Android) or a web app first?
- Pricing model and price point.
