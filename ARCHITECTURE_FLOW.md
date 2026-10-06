# 📘 In-Depth Project Sections: UI & Technical Flow

This document provides a highly detailed explanation of your specific parts of the system. It explains exactly where things are located on the screen (UI), what the user clicks, and then the exact technical code path it takes all the way down to the database.

---

## 1. Staff Memos Flow (Adding a Memo)
*This is the feature that allows university staff to write internal comments about a student's application. A pending memo acts as a strict blocker that prevents approval.*

### 🖥️ 1. UI User Journey (Where is the button?)
1. **Login**: A staff member logs into the React web portal.
2. **Dashboard**: They navigate to the **Staff Dashboard** (the Applications view).
3. **Open Panel**: On any student's application card, there is a **"💬 Discuss"** button. Clicking this slides out the **Internal Memos Panel** on the right side of the screen.
4. **The Button**: At the bottom of this panel, the staff member types a note into the text box and clicks the **"Send"** (or Save) button.

### ⚙️ 2. Technical Execution Flow
* **React Component**: `frontend-react/src/components/admin/InternalMemosPanel.jsx`
* **React Function Triggered**: `handleAddMemo()` (Located around line 46)
* **API Request**: The React app makes an HTTP `POST` request to `http://localhost:5168/api/Memos`.
* **Backend Controller**: Hits `backend-dotnet/Controllers/MemosController.cs` -> `CreateMemo()` method.
* **DTO (Data Transfer Object)**: The API receives a `CreateMemoDto` which contains:
  - `ApplicationId` (Which student this memo is for)
  - `MemoText` (The actual comment text)
* **Database Action**: The C# backend creates a new record in the PostgreSQL `Memos` table. Crucially, it sets the `Status` of this memo to `"Pending"`.
* **UI Reaction**: The React frontend detects the pending memo and instantly changes the student's Approve button to say **"Resolve Memos to Approve"**, locking it so they cannot be approved yet.

---

## 2. Staff Approvals Flow (Approving a Student)
*This is the process where a staff member officially approves a student, verifying they are cleared to be sent to the company.*

### 🖥️ 1. UI User Journey (Where is the button?)
1. **Dashboard**: The staff member is looking at the list of students in the **Staff Dashboard**.
2. **The Button**: On the student's application card, they click the button labeled **"Approve Candidate"**. (Note: If there is a pending memo, this button is disabled and says "Resolve Memos to Approve" instead).
3. **Confirmation Modal**: A popup modal appears asking "Confirm Approval?". 
4. **Final Click**: The staff member clicks the **"Confirm Approval"** button in the modal.

### ⚙️ 2. Technical Execution Flow
* **React Component**: `frontend-react/src/pages/ApplicationsPage.tsx`
* **React Function Triggered**: `handleAction(id, 'approve')` (Located around line 209)
* **API Request**: Makes an HTTP `POST` request to `http://localhost:5168/api/Applications/{applicationId}/admin-approve`.
* **Backend Controller**: Hits `backend-dotnet/Controllers/ApplicationsController.cs` -> `AdminApprove()` method.
* **The Blocker Check (Security)**: Before doing anything, the C# Controller queries the database: `dbContext.Memos.AnyAsync(m => m.Status == "Pending")`. If it finds a pending memo, it stops immediately and throws a `400 BadRequest` error.
* **Backend Service**: If there are no pending memos, it passes the request to `backend-dotnet/Services/ApplicationService.cs` -> `AdminDecisionAsync()`.
* **Database Action**: Updates the `Applications` table, changing the student's status from `Agent_Evaluated` to `Admin_Approved`.
* **Agent Wake-Up Call**: The C# backend then fires a webhook `POST` request to `http://127.0.0.1:8000/resume` to wake up the sleeping Python AI Agent, letting it know the human has approved the application.

---

## 3. Action Agent Flow (AI Evaluation)
*This is the Python LangGraph AI agent that runs silently in the background, acting as an automated evaluator before the human staff ever sees the application.*

### 🖥️ 1. UI User Journey (Where is the trigger?)
1. **No UI Button**: This is a pure background process! It triggers automatically the moment a student successfully applies for a job from the Flutter mobile app.

### ⚙️ 2. Technical Execution Flow
* **AI Processing**: The Python AI Agent reads the student's CV and the job's strict requirements, giving the student a `MatchScore`.
* **API Request**: Once the Python AI finishes grading, *it* makes an HTTP `POST` request back to the C# Backend at `http://localhost:5168/api/Applications/webhook/evaluation-result`.
* **Backend Controller**: Hits `backend-dotnet/Controllers/ApplicationsController.cs` -> `ReceiveEvaluationResult()` method.
* **DTO (Data Transfer Object)**: It receives a `WebhookEvaluationResultDto` containing:
  - `AppId` (The application ID)
  - `MatchScore` (The AI's calculated score, e.g., 85.5)
  - `ActionToTake` (What the AI thinks should happen)
* **Database Action**: The C# backend updates the student's record with their new score and changes their status to `Agent_Evaluated`.
* **The Wait**: The Python AI enters a "sleeping" state, suspending its thread. It will sit there indefinitely until the Staff Approvals Flow (Flow 2 above) wakes it up with the `/resume` endpoint.

---

## 4. Student Feed Flow (Viewing Jobs)
*This is how the Flutter mobile app retrieves and displays the list of available jobs for the student.*

### 🖥️ 1. UI User Journey (Where is the trigger?)
1. **Mobile App**: The student opens the Flutter mobile application on their phone.
2. **The Trigger**: The student taps the **"Jobs"** or **"Feed"** icon on the bottom navigation bar.
3. **Automatic Load**: The screen opens and a loading spinner appears while it automatically fetches the data.

### ⚙️ 2. Technical Execution Flow
* **Flutter Screen**: `frontend_flutter/lib/features/jobs/presentation/screens/job_feed_screen.dart`
* **Flutter Service Function**: When the screen loads, it calls `ApiService().getJobFeed()` (located in `frontend_flutter/lib/core/services/api_service.dart`).
* **API Request**: Makes an HTTP `GET` request to `http://localhost:5168/api/Jobs/feed`.
* **Backend Controller**: Hits `backend-dotnet/Controllers/JobController.cs` -> `GetJobFeed()` method.
* **Backend Service**: Passes the request to `backend-dotnet/Services/JobService.cs` -> `GetJobFeedAsync()`.
* **Database Action**: The C# backend queries the `Jobs` table. It filters out inactive jobs, checks the student's GPA against the job's requirements, and handles search pagination.
* **DTO (Data Transfer Object)**: The data is packaged into a list of `JobFeedDto` objects. Each object contains the `jobId`, `jobTitle`, `companyName`, `duration`, `stipend`, etc.
* **UI Update**: The C# backend returns this JSON array to the Flutter app, which then draws the beautiful Job Cards on the student's screen.
