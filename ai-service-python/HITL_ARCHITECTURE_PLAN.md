# Human-in-the-Loop (HITL) Architecture Plan

This document outlines the proposed transition to a **Job-Triggered, Human-in-the-Loop (HITL)** AI pipeline. Keep this document as a master reference if the team decides to pivot to this new flow.

## 1. The Core Differences (Old vs. New)
* **Old Flow (Student-Triggered):** A student applies -> AI is triggered for that 1 student -> AI finishes completely -> Webhook sent to .NET -> Admin reviews static result.
* **New Flow (Job-Triggered + HITL):** A new job is posted -> AI fetches ALL matching students -> AI processes them but **PAUSES** at Agent 4 -> AI waits for Human Admin to click Approve/Reject in the React UI -> AI wakes up, sends emails, and finishes.

---

## 2. The 4-Agent Flow in the New Architecture
The core roles of the agents remain the same, but the execution is paused midway:

1. **Agent 1 (Planner):** Receives a newly posted `Job ID` and a list of 50-100 `Student IDs`. It plans the execution batch.
2. **Agent 2 (Scorer):** Analyzes each CV against the job description and assigns a score. If the score is too low, the student is instantly filtered out (no summary generated).
3. **Agent 3 (Summary):** If the score is high, it generates the detailed evaluation summary. It saves this to the LangGraph memory (`AgentState`).
4. **Agent 4 (Validate & Wait):** 
   - Formats the summary.
   - **[NEW]** Sends a Webhook to `.NET` saying "Ready for Human Review".
   - **[NEW]** The LangGraph **PAUSES** execution (using an `interrupt` or Checkpointer).
   - **[NEW]** Waits for the human Admin to verify in the React UI.
   - **[NEW]** Once verified, it wakes up and sends the final filter-out / approval email to the student.

---

## 3. Required Code Changes (The Implementation Plan)

If we proceed with this new flow, here is the exact checklist of changes across the entire stack:

### A. Python AI Service (`ai-service-python`)
- [ ] **LangGraph Checkpointer:** Implement `MemorySaver` or `SqliteSaver` in `main.py` when compiling the graph. This is mandatory; otherwise, the AI will lose all memory when it pauses.
- [ ] **Add `interrupt_before` / `interrupt_after`:** Tell LangGraph to pause execution right before or after the Agent 4 node.
- [ ] **Create a `/resume` Endpoint:** Build a new FastAPI endpoint (e.g., `POST /resume-evaluation`). When called, this endpoint will take the human's feedback (Approve/Reject), update the graph state, and resume the graph execution so Agent 4 can send the email.
- [ ] **Update Trigger Endpoint:** Switch from processing one `application_id` to accepting a `job_id` and an array of `student_ids` (this is partially built in `/analyze`).

### B. .NET Backend (`backend-dotnet`)
- [ ] **Rewrite Background Trigger:** Change `EvaluationTriggerService.cs` from watching for `Pending` Applications to watching for **newly created Jobs**. It should gather all relevant Student IDs and fire a massive batch HTTP POST to Python.
- [ ] **Webhook Update:** Ensure the webhook receiver (`ApplicationsController.cs`) can handle the "Ready for Review" status.
- [ ] **New UI Bridge Endpoint:** Create a new endpoint (e.g., `POST /api/admin/human-verify`) that the React frontend calls when the Admin clicks "Approve". This endpoint must forward that HTTP request to Python's `/resume` endpoint.

### C. React Frontend (`frontend-react`)
- [ ] **Update API Call:** The beautiful Candidate Profile Modal we built (with the Google Docs PDF Viewer) stays exactly the same visually! However, the `onApprove` and `onReject` functions must be updated. Instead of just doing a local database update, they must call the new .NET `human-verify` endpoint to trigger the Python wake-up sequence.

---

## 4. Important Considerations for the Team
* **Time / Performance:** Processing 100 students at once will take 15-20 minutes. Do not remove the Async Webhook architecture; it is the only thing preventing the .NET server from crashing during this long wait.
* **API Rate Limits:** If we use Gemini or OpenAI, sending 100 requests at the exact same time will cause `429 Too Many Requests` errors. The Python logic must process the batch of students sequentially or in small chunks.
* **State Management:** A SQL-backed Checkpointer (`SqliteSaver` or `PostgresSaver`) is highly recommended over `MemorySaver` so that if the Python server restarts while waiting for human approval, the AI doesn't lose the student's progress.

---

## 5. The "Iterative Webhook" Strategy (Highly Recommended)
When triggering a batch of 100 students for a Job, do **NOT** wait for all 100 students to finish before sending one giant JSON webhook to `.NET`. 

**The Winning Strategy:**
* Python loops through the students one by one.
* As soon as Agent 4 finishes validating **Student #1**, Python immediately fires a Webhook to `.NET` just for that specific student.
* `.NET` receives it and updates the Database to `Agent_Evaluated`.
* Python moves on to process Student #2 in the background.

**Why this is amazing for the React UI:**
Because the Admin Dashboard dynamically queries `.NET` for evaluated applications, the HR Admin doesn't have to wait 20 minutes to see results. Students will literally start popping up on the Admin Dashboard **one by one, every 10 seconds**! The Admin can begin reviewing and clicking "Approve" on Student #1 while the AI is still quietly evaluating Student #20 in the background.
