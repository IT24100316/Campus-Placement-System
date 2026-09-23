# 🚀 Campus Placement System - Complete Developer Onboarding Guide

Hey there! 👋 Welcome to the **Campus Placement System** project! 

This guide is designed to get you up and running on your local machine smoothly, even if you are setting up the project from scratch. Follow the steps below and you'll have all 4 services running in no time!

---

## 🧭 System Overview (What we're building)

Our project uses a modern multi-service architecture:

```text
📁 Campus-Placement-System/
├── ⚙️ backend-dotnet/       👉 ASP.NET Core 8 Web API (Handles DB & Business Logic)
├── 🤖 ai-service-python/    👉 Python FastAPI Service (AI Agent & Smart Matching Engine)
├── 💻 frontend-react/       👉 React + Vite + TypeScript (Student & Admin Web Dashboard)
└── 📱 frontend_flutter/     👉 Flutter App (Mobile Application for Students)
```

---

## 🛠️ Phase 1: Prerequisites Check

Before cloning or installing packages, make sure you have these software tools installed on your computer:

| Tool | Recommended Version | Download / Check Command |
|---|---|---|
| **.NET SDK** | `.NET 8.0` | `dotnet --version` \| [Download .NET 8](https://dotnet.microsoft.com/download/dotnet/8.0) |
| **Node.js** | `v18.0.0+` | `node -v` \| [Download Node.js](https://nodejs.org/) |
| **Python** | `3.10+` | `python --version` \| [Download Python](https://www.python.org/downloads/) |
| **PostgreSQL** | `v14+` with pgAdmin | `psql --version` \| [Download PostgreSQL](https://www.postgresql.org/download/) |
| **Flutter SDK** | `v3.19+` | `flutter --version` \| [Download Flutter](https://docs.flutter.dev/get-started/install) |
| **Git** | Any recent version | `git --version` \| [Download Git](https://git-scm.com/) |

---

## ⚡ Phase 2: First-Time Setup (Step-by-Step)

Follow these steps **in order** when setting up the project for the very first time.

### 🐘 Step 1: Set up the PostgreSQL Database

1. Open **pgAdmin** (or open your PostgreSQL terminal / `psql`).
2. Log in with your PostgreSQL superuser account (`postgres`).
3. Create a fresh database named **`SEF_Project`**:
   ```sql
   CREATE DATABASE "SEF_Project";
   ```

---

### ⚙️ Step 2: Set up the Backend (.NET 8 Web API)

1. Open terminal and navigate to the backend folder:
   ```bash
   cd backend-dotnet
   ```

2. **Configure Database Connection:**
   Since local settings files containing passwords are excluded from Git for security, check if `appsettings.Development.json` exists. If not, create it in `backend-dotnet/` with the following content (or update `appsettings.json`):
   ```json
   {
     "ConnectionStrings": {
       "DefaultConnection": "Host=localhost;Port=5432;Database=SEF_Project;Username=postgres;Password=YOUR_POSTGRES_PASSWORD"
     },
     "Logging": {
       "LogLevel": {
         "Default": "Information",
         "Microsoft.AspNetCore": "Warning"
       }
     },
     "AllowedHosts": "*"
   }
   ```
   > ⚠️ **Important:** Replace `YOUR_POSTGRES_PASSWORD` with the actual password you set up when installing PostgreSQL.

   Keep credentials outside tracked files. You can also use .NET user secrets:
   ```bash
   dotnet user-secrets set "ConnectionStrings:DefaultConnection" "Host=localhost;Port=5432;Database=SEF_Project;Username=postgres;Password=YOUR_POSTGRES_PASSWORD"
   dotnet user-secrets set "Supabase:Url" "https://YOUR_PROJECT.supabase.co"
   dotnet user-secrets set "Supabase:ServiceRoleKey" "YOUR_SERVICE_ROLE_KEY"
   dotnet user-secrets set "SendGrid:ApiKey" "YOUR_SENDGRID_API_KEY"
   dotnet user-secrets set "SendGrid:FromEmail" "verified-sender@example.edu"
   ```
   The backend creates the private Supabase bucket `verification-docs` on the first upload. If Supabase is not configured, development uploads use `backend-dotnet/App_Data/verification-docs`.

3. **Install Entity Framework Core Tools:**
   ```bash
   dotnet tool install --global dotnet-ef
   ```
   *(If it's already installed, you can update it with `dotnet tool update --global dotnet-ef`)*

4. **Restore Packages & Apply Database Migrations:**
   ```bash
   dotnet restore
   dotnet ef database update
   ```
   *🎉 This command automatically creates all database tables in your PostgreSQL `SEF_Project` database!*

---

### 🤖 Step 3: Set up the AI Service (Python FastAPI)

1. Open a new terminal and navigate to the Python service folder:
   ```bash
   cd ai-service-python
   ```

2. **Create and Activate a Virtual Environment:**
   * 🪟 **Windows (PowerShell):**
     ```powershell
     python -m venv .venv
     .\.venv\Scripts\Activate.ps1
     ```
   * 🍎 / 🐧 **macOS / Linux:**
     ```bash
     python3 -m venv .venv
     source .venv/bin/activate
     ```

3. **Install Dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

4. **Add API Environment Keys:**
   Create a `.env` file inside `ai-service-python/` directory and add your API keys:
   ```env
   GOOGLE_API_KEY=your_gemini_api_key_here
   OPENAI_API_KEY=your_openai_api_key_here
   SENDGRID_API_KEY=your_sendgrid_api_key_here
   SENDGRID_FROM_EMAIL=verified-sender@example.edu
   ```

---

### 💻 Step 4: Set up the Web Dashboard (React + Vite)

1. Open a new terminal and navigate to the React folder:
   ```bash
   cd frontend-react
   ```

2. **Install Node Packages:**
   ```bash
   npm install
   ```

---

### 📱 Step 5: Set up the Mobile Application (Flutter)

1. Open a new terminal and navigate to the Flutter folder:
   ```bash
   cd frontend_flutter
   ```

2. **Fetch Dependencies:**
   ```bash
   flutter pub get
   ```

3. Pass the backend URL when running on a device or Android emulator:
   ```bash
   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5168/api
   ```
   Use `http://localhost:5168/api` for desktop/iOS simulator where localhost reaches the development machine.

---

## ▶️ Phase 3: Running the Entire System

To run and work on the application, open **4 separate terminal windows** (or VS Code integrated terminals) and start each service:

| Service | Folder | Terminal Command | Local URL / Swagger Docs |
|---|---|---|---|
| **1. Backend API** | `backend-dotnet/` | `dotnet run` | 🌐 `https://localhost:7198/swagger` |
| **2. AI Service** | `ai-service-python/` | `uvicorn main:app --reload --port 8000` | 🤖 `http://127.0.0.1:8000/docs` |
| **3. Web Portal** | `frontend-react/` | `npm run dev` | 💻 `http://localhost:5173` |
| **4. Mobile App** | `frontend_flutter/` | `flutter run` | 📱 Mobile Emulator / Device |

### Verification commands

```bash
dotnet test backend-dotnet.Tests/backend-dotnet.Tests.csproj
cd ai-service-python && .venv/bin/python -m pytest -q
cd frontend-react && npm run build
cd frontend_flutter && flutter analyze
```

Swagger documents every implemented endpoint, including private document upload/view, student registration and CV upload, Agent 4 evaluation, the administrator approval queue/gate, and interview scheduling.

---

## 🛠️ Troubleshooting & Helpful Tips

#### ❓ Issue 1: `dotnet ef` command not found
* **Solution:** Run `dotnet tool install --global dotnet-ef` and close/re-open your terminal window so the PATH updates.

#### ❓ Issue 2: Script execution error in PowerShell when activating Python `.venv`
* **Solution:** Windows restricts script execution by default. Run this in PowerShell as Administrator:
  ```powershell
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
  ```

#### ❓ Issue 3: PostgreSQL Connection Refused / Invalid Password
* **Solution:**
  1. Open your Windows Services app (`services.msc`) and verify that `postgresql-x64-<version>` service status is **Running**.
  2. Double-check your password in `backend-dotnet/appsettings.Development.json`.

#### ❓ Issue 4: CORS Errors between Frontend & Backend
* **Solution:** The backend API and Python AI service are configured to accept requests from `http://localhost:5173`. Make sure Vite starts on port `5173`.

---

## 🤝 Need Help?
If you hit any unexpected errors, take a screenshot of your terminal error log and check in with the project leader. Happy coding! 🚀
