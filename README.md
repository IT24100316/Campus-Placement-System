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

### 2. Current Development Work (Active Sprints)

#### 🌐 Landing Page UI & Experience
- **Design Reference**: Faithfully adapted from the Google Stitch design specification (`UI/LandingPage/DESIGN.md`, `code.html`, and `screen.png`) featuring the *Autonomous Placement Architecture* theme.
- **Component Architecture (`frontend-react/src/components/landing/`)**:
  - `Navbar.tsx`: Sticky top navigation bar with blur backdrop, brand identity, anchor links, action buttons, and responsive drawer.
  - `Hero.tsx`: High-impact hero section with value proposition pill, call-to-action buttons, university trust strip, and interactive **Candidate Match Preview Card**.
  - `Metrics.tsx`: 4-column statistical milestone banner (`36 Hours`, `94.2%`, `120K+`, `0 Bias`).
  - `Features.tsx`: 3 clean purpose-built feature cards (*Semantic Skill Matching*, *AI CV Summarization*, *Automated Interview Scheduling*).
  - `DualAudience.tsx`: Two-column value proposition distinguishing benefits for **Company HRs** and **University Admins**.
  - `CallToAction.tsx`: Bottom conversion section.
  - `Footer.tsx`: Enterprise footer with policies and copyright.

#### 📝 Company-Side Registration & Approval Engine
- **Design References**: Adapted from `UI/registration` and `UI/registration_prending` Google Stitch designs.
- **Role Switcher**: Seamless tabbed toggle between **Company HR** (administrative authority) and **Company Staff** (technical interviewer).
- **Form Architecture & Real-Time Validations**:
  - **Company HR**: Full Name, Corporate Email, Password (with live strength meter), Confirm Password, Registered Company Name, Industry Sector dropdown, Contact Telephone, and Business Registration (BR) Document dropzone (supports PDF/PNG/JPG up to 10MB).
  - **Company Staff**: Full Name, Corporate Email, Password, Confirm Password, Select Existing Company dropdown (dynamically feeds newly approved entities), Employee ID, and Job Designation.
  - Inline error notifications under each invalid input with real-time feedback.
- **Pending Approval Screen (`PendingApprovalScreen.tsx`)**:
  - Displays **Pending • Waiting for Admin Approval** badge.
  - Generates institutional reference code (`Ref: REG-2025-XXXXX`).
  - Verification Stepper: 4-stage lifecycle (Application Submitted, Document Verification, Admin Sign-off, Account Activation).
  - Profile Summary Card detailing applicant details, company metadata, and encrypted document preview.
- **Admin Approvals Dashboard (`AdminApprovalsView.tsx`)**:
  - Administrative oversight table with KPI counters (*Waiting Approval*, *Company HRs*, *Company Staff*, *Authorized Total*).
  - Role filter tabs (*All*, *Pending*, *HR Accounts*, *Staff Accounts*).
  - Full application review modal with BR document inspect view.
  - Interactive **Approve** and **Reject** actions. Approving an HR user automatically adds their company to the Staff registration dropdown.
- **Login Page & Dedicated Authentication Engine (`LoginPage.tsx`, `LoginModal.tsx`)**:
  - **Design Reference**: Faithfully implemented following the Google Stitch design specification (`UI/Login/DESIGN.md`, `code.html`, and `screen.png`).
  - **3-Role Segmented Switcher**:
    - **Company HR**: Corporate administrative access (`c.vance@acmeglobal.tech` / `Vanguard#2024Secure!`).
    - **Company Staff**: Technical recruiter and employee credentials (`d.miller@acmeglobal.tech` / `StaffPass@2025!`, Staff ID: `ACM-STF-1042`).
    - **Institutional Admin**: University placement director controls (`admin@campusai.edu` / `Admin@2025`).
  - **Context Guidance**: Role-specific contextual security guidance and dynamic domain badges for each role.
  - **Security Badges & Banners**: 256-bit TLS, FERPA/SOC-2 certifications, MFA indicators, and real-time application lifecycle lookup.
  - **Pending-Detection Routing**: Automatically intercepts pending accounts and routes applicants to their real-time verification lifecycle.
  - **Direct Cockpit Routing**: Instant navigation into the **Admin Approvals Cockpit** upon administrator login.

#### 🗄️ Backend Data Architecture & API Controllers
- **Models & Migration**:
  - Created [CompanyStaffProfile.cs](backend-dotnet/Models/CompanyStaffProfile.cs) model linking staff members (`FullName`, `StaffId`, `JobPosition`) to `User` and an existing `CompanyProfile`.
  - Added `ContactPersonName` and `Phone` fields to [CompanyProfile.cs](backend-dotnet/Models/CompanyProfile.cs).
  - Applied EF Core migration `20260919155201_AddCompanyStaffProfileAndContactDetails` to the cloud Supabase PostgreSQL database.
- **Controllers & DTOs**:
  - [AuthController.cs](backend-dotnet/Controllers/AuthController.cs):
    - `POST /api/auth/login`: Authenticates institutional administrators, Company HRs, and Company Staff users. Returns differentiated role metadata (`CompanyStaff`, `CompanyHR`, `Admin`), associated company profile data, and intercepts pending/rejected applications.
    - `POST /api/auth/register-hr`: Validates unique email, hashes password with `PasswordHasher<User>`, creates `User` + `CompanyProfile` with `Pending` status.
    - `POST /api/auth/register-staff`: Links staff member to selected company with `Pending` status.
    - `GET /api/auth/companies`: Provides approved company directory for staff registration.
  - [AdminController.cs](backend-dotnet/Controllers/AdminController.cs):
    - `GET /api/admin/pending-approvals`: Lists all pending registrations with profile and document data.
    - `POST /api/admin/approve/{userId}`: Sets user status to `Approved`.
    - `POST /api/admin/reject/{userId}`: Sets user status to `Rejected`.
- **In-Built Admin Account Seeding**:
  - `Program.cs` automatically seeds a single institutional administrator on service startup if one does not already exist:
    - **Email**: `admin@campusai.edu`
    - **Role**: `UserRole.Admin`
    - **Status**: `AccountStatus.Approved`
    - **Password**: `Admin@2025` (PBKDF2 SHA-256 hashed)

---

## 🔑 Demo & Test Credentials

| Role | Email | Password | Behavior / Destination |
| :--- | :--- | :--- | :--- |
| **Institutional Admin** | `admin@campusai.edu` | `Admin@2025` | Authenticates directly into the **Admin Approvals Dashboard** |
| **Pending Recruiter (HR)** | `c.vance@acmeglobal.tech` | `Vanguard#2024Secure!` | Intercepted & routed to the **Pending Approval Screen** |

---

## 🚀 Running the Services Locally

### 1. Web Frontend
```bash
cd frontend-react
npm install
npm run dev
```
Accessible at `http://localhost:5173`. Use the bottom-right floating switcher or the Navbar "Register" / "Login to Dashboard" buttons to navigate across the **Landing Page**, **Registration Flow**, and **Admin Approvals Dashboard**.

### 2. Backend Web API
```bash
cd backend-dotnet
dotnet restore
dotnet run
```
Swagger UI will be accessible at `http://localhost:5168/swagger`.