# 🎓 Campus Placement System (CampusAI)

An enterprise-grade, autonomous placement and recruitment platform connecting university talent, institutional placement directors, and corporate recruiters through explainable AI matching, automated screening, and streamlined interview scheduling.

---

## 🏗️ System Architecture & Repository Overview

This repository is structured as a multi-service distributed architecture:

```text
Campus-Placement-System/
├── backend-dotnet/       👉 ASP.NET Core 8 Web API (Business logic, EF Core 8 & PostgreSQL)
├── ai-service-python/    👉 Python FastAPI Microservice (LangChain, LangGraph, AI Agents)
├── frontend-react/       👉 React 19 + TypeScript + Vite (Web Portal & Dashboards)
└── frontend_flutter/     👉 Flutter Application (Cross-platform Student Mobile App)
```

---

## 📌 Implementation Status & Attribution

To maintain accurate technical documentation, the project distinguishes between functionality present in the initial cloned repository and the features actively implemented during current development sprints:

### 1. Existing Project Setup (Pre-existing in Cloned Repository)
The following components and foundations were established in the original project setup:
- **Backend Service (`backend-dotnet`)**:
  - ASP.NET Core 8 Web API project configuration.
  - Entity Framework Core 8 with Npgsql PostgreSQL provider.
  - Core data models: `User`, `StudentProfile`, `CompanyProfile`, `Job`, and `Application` with PostgreSQL array and JSONB configurations.
  - Initial database migration (`InitialMultiAgentCreate`).
- **AI Orchestration Service (`ai-service-python`)**:
  - FastAPI service structure with CORS and `/health` route.
  - Virtual environment and dependencies definition (`requirements.txt`).
  - Architecture scaffolds for multi-agent workflows (`planner.py`, `validation.py`, `analysis.py`, `action.py`).
- **Mobile Client (`frontend_flutter`)**:
  - Flutter multi-platform workspace scaffold (`pubspec.yaml`).
- **Web Frontend (`frontend-react`)**:
  - Initial Vite + React 19 + TypeScript starter scaffold.

---

### 2. Current Development Work (Active Sprint: Landing Page)
The following functionality and design architecture has been implemented during this sprint:

#### 🌐 Landing Page UI & Experience
- **Design Reference**: Faithfully adapted from the Google Stitch design specification (`UI/LandingPage/DESIGN.md`, `code.html`, and `screen.png`) featuring the *Autonomous Placement Architecture* theme.
- **Design Tokens & Typography**:
  - Configured Google Fonts: **Plus Jakarta Sans** (Headlines & Display), **Inter** (Body & Labels), and **Material Symbols Outlined**.
  - Tailwind CSS integration with curated institutional color palette (`primary`: `#004ac6`, `primary-container`: `#2563eb`, `secondary`: `#4b41e1`, `surface-container-low`: `#f8fafc`, crisp 1px hairline borders).
- **Component Architecture (`frontend-react/src/components/`)**:
  - `layout/Navbar.tsx`: Sticky top navigation bar with blur backdrop, brand identity, section anchor links, action buttons, and responsive mobile toggle drawer.
  - `landing/Hero.tsx`: High-impact hero section with value proposition pill, call-to-action buttons, university trust strip (`IIT Delhi`, `BITS Pilani`, `Stanford CS`, `IIT Bombay`, `NUS Singapore`), and interactive **Candidate Match Preview Card** featuring confidence score, skill chips, benchmark rankings, and auto-scheduling indicator.
  - `landing/Metrics.tsx`: 4-column statistical milestone banner (`36 Hours` time to offer, `94.2%` retention, `120K+` verified profiles, `0 Bias` evaluations).
  - `landing/Features.tsx`: 3 clean purpose-built feature cards (*Semantic Skill Matching*, *AI CV Summarization*, *Automated Interview Scheduling*).
  - `landing/DualAudience.tsx`: Two-column value proposition section distinguishing benefits and tailored actions for **Company HRs** and **University Admins**.
  - `landing/CallToAction.tsx`: Bottom conversion section encouraging company registration and sales inquiries.
  - `layout/Footer.tsx`: Enterprise footer with brand marks, security, privacy, terms, and copyright.
  - `pages/LandingPage.tsx`: Modular assembly of all landing page components.

---

## 🚀 Running the Web Frontend Locally

```bash
# Navigate to the frontend directory
cd frontend-react

# Install dependencies
npm install

# Start Vite development server
npm run dev

# Build for production
npm run build

# Run linter
npm run lint
```
The application will be accessible at `http://localhost:5173`.