# 💻 Campus Placement System — Web Frontend (`frontend-react`)

Modern web portal for the Campus Placement System, built with **React 19**, **TypeScript**, **Vite**, and **Tailwind CSS**.

---

## 🎨 Design System & Reference

The UI design is adapted from the Google Stitch design reference located in [`UI/LandingPage`](../UI/LandingPage/):
- **Design Specification**: `UI/LandingPage/DESIGN.md` (*Autonomous Placement Architecture*)
- **Layout & Structure Reference**: `UI/LandingPage/code.html`
- **Visual Reference**: `UI/LandingPage/screen.png`

### Typography & Colors
- **Display & Headings**: `Plus Jakarta Sans` (weights 500, 600, 700, 800) with kerning `-0.01em` to `-0.02em`.
- **Body & Metadata**: `Inter` (weights 400, 500, 600, 700).
- **Icons**: `Material Symbols Outlined`.
- **Color Palette**:
  - `primary`: `#004ac6` / `#2563eb` (Royal Blue)
  - `secondary`: `#4b41e1` (Indigo)
  - `on-surface`: `#0b1c30` / `#0f172a` (Slate 900)
  - `on-surface-variant`: `#5a687d` / `#334155` (Slate 700)
  - `outline`: `#e2e8f0` (Slate 200 hairline borders)
  - `surface-container-low`: `#f8fafc` (Slate 50 canvas)
  - `surface`: `#ffffff` (Card background)

---

## 📂 Component Architecture

```text
src/
├── components/
│   ├── layout/
│   │   ├── Navbar.tsx         # Fixed blur navigation with branding, anchor links, and mobile drawer
│   │   └── Footer.tsx         # Lightweight enterprise footer with policies & copyright
│   └── landing/
│       ├── Hero.tsx           # Value proposition, trust strip, and candidate match card
│       ├── Metrics.tsx        # 4-column statistical milestones banner
│       ├── Features.tsx       # 3 clean feature cards (Matching, Summarization, Scheduling)
│       ├── DualAudience.tsx   # Two-column value props for Company HRs vs University Admins
│       └── CallToAction.tsx   # Conversion block with registration and contact actions
├── pages/
│   └── LandingPage.tsx        # Page composition combining layout & landing sections
├── App.tsx                    # Root application component
├── index.css                  # Base layout resets, typography tokens & scroll behaviors
└── main.tsx                   # Application bootstrap
```

---

## 📌 Implementation Status

### Cloned Setup (Pre-existing)
- React 19 + TypeScript + Vite boilerplate.

### Completed Work (Current Development)
- [x] Configure Google Fonts (`Plus Jakarta Sans`, `Inter`, `Material Symbols Outlined`).
- [x] Configure Tailwind CSS design tokens and theme extensions.
- [x] Responsive Navigation Bar with mobile toggle drawer.
- [x] Hero section with university trust strip and Candidate Match Preview card.
- [x] Metrics ribbon with placement milestones.
- [x] Core Features grid.
- [x] Dual-Audience section for Company HRs & University Admins.
- [x] Call-To-Action conversion section.
- [x] Enterprise Footer.
- [x] Page composition and responsive layout integration.

---

## 🛠️ Available Scripts

In the `frontend-react` directory, you can run:

```bash
# Start local development server (http://localhost:5173)
npm run dev

# Build for production with TypeScript type-checking
npm run build

# Run ESLint validation
npm run lint

# Preview the production build locally
npm run preview
```
