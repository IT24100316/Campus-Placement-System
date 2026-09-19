# 💻 Campus Placement System — Web Frontend (`frontend-react`)

Modern web portal for the Campus Placement System, built with **React 19**, **TypeScript**, **Vite**, **Tailwind CSS**, and **Lucide React**.

---

## 🎨 Design System & Reference

The UI design is adapted from the Google Stitch design references:
- **Landing Page**: `UI/LandingPage/` (*Autonomous Placement Architecture*)
- **Recruiter Registration**: `UI/registration/`
- **Pending Approval Screen**: `UI/registration_prending/`
- **Login Portal**: `UI/Login/` (*Recruitment Cockpit & Multi-Role Authentication*)

### Typography & Colors
- **Display & Headings**: `Plus Jakarta Sans` (weights 500, 600, 700, 800) with kerning `-0.01em` to `-0.02em`.
- **Body & Metadata**: `Inter` (weights 400, 500, 600, 700).
- **Icons**: `Lucide React` and `Material Symbols Outlined`.
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
├── types/
│   └── auth.ts                # TypeScript interfaces for HR, Staff, Status, and Companies
├── services/
│   └── authService.ts         # Persistent data layer with .NET backend API sync & fallback
├── components/
│   ├── layout/
│   │   ├── Navbar.tsx         # Fixed blur navigation with brand logo, anchor links, and mobile drawer
│   │   └── Footer.tsx         # Lightweight enterprise footer with policies & copyright
│   ├── landing/
│   │   ├── Hero.tsx           # Value proposition, trust strip, and candidate match card
│   │   ├── Metrics.tsx        # 4-column statistical milestones banner
│   │   ├── Features.tsx       # 3 clean feature cards (Matching, Summarization, Scheduling)
│   │   ├── DualAudience.tsx   # Two-column value props for Company HRs vs University Admins
│   │   └── CallToAction.tsx   # Conversion block with registration actions
│   ├── auth/
│   │   ├── RegisterForm.tsx   # Recruiter registration with HR vs Staff tab toggle & validations
│   │   ├── PendingApprovalScreen.tsx # 4-step verification stepper & profile summary card
│   │   └── LoginModal.tsx     # Sign-in modal with 1-click autofill for Admin, HR & Staff
│   └── admin/
│       └── AdminApprovalsView.tsx # Administrative oversight table to review, approve & reject accounts
├── pages/
│   ├── LandingPage.tsx        # Full landing page layout
│   ├── RegisterPage.tsx       # Registration flow manager (Form -> Pending screen)
│   ├── LoginPage.tsx          # Dedicated 3-Role login page matching UI/login specification
│   └── AdminDashboardPage.tsx # Admin review portal
├── App.tsx                    # Top-level view routing, login navigation & floating dock
├── index.css                  # Base layout resets, typography tokens & scroll behaviors
└── main.tsx                   # Application bootstrap
```

---

## 🔑 Demo & Test Credentials

| Role | Email | Password | Details / Destination |
| :--- | :--- | :--- | :--- |
| **Institutional Admin** | `admin@campusai.edu` | `Admin@2025` | **Admin Approvals Dashboard** (Full oversight & approval controls) |
| **Company HR (Employer)** | `c.vance@acmeglobal.tech` | `Vanguard#2024Secure!` | **Pending Approval Screen** (Corporate incorporation review) |
| **Company Staff (Recruiter)** | `d.miller@acmeglobal.tech` | `StaffPass@2025!` | **Pending Approval Screen** (Employee ID `ACM-STF-1042`, Talent Acquisition) |

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
- [x] **Recruiter Registration Flow**:
  - [x] Tabbed Role Switcher (**Company HR** vs **Company Staff**).
  - [x] Tailored fields for HR (Company, Industry, Phone, BR Document upload).
  - [x] Tailored fields for Staff (Dynamic Company dropdown, Staff ID, Job Title).
  - [x] Real-time inline field validations & password strength indicator.
- [x] **Pending Approval Screen**:
  - [x] Reference code generator (`Ref: REG-2025-XXXXX`).
  - [x] 4-stage verification lifecycle stepper.
  - [x] Submitted profile summary card with attached document pill.
- [x] **Admin Approvals Dashboard**:
  - [x] KPI statistics banner (*Waiting Approval*, *Company HRs*, *Company Staff*, *Authorized Total*).
  - [x] Filter tabs (*Pending*, *All*, *HR*, *Staff*).
  - [x] Document preview modal with one-click **Approve** and **Reject** actions.
  - [x] Approving an HR company automatically populates it into the Staff registration dropdown!
- [x] **Authentication & Sign-in**:
  - [x] Global login modal triggered from "Login to Dashboard" buttons.
  - [x] 1-click autofill for Institutional Admin and Pending HR demo records.
  - [x] Smart route handling: logs Admin into the Admin Dashboard; routes pending applicants to their Pending Approval status screen.
- [x] Seamless navigation routing between Landing Page, Registration, and Admin Portal.

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
