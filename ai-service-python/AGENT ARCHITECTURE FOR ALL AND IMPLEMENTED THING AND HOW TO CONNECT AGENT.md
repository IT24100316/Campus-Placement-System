# The Ultimate Agent Architecture Guide 🚀
*A comprehensive guide for our team on the newly implemented Async Webhook Architecture, how our agents connect, and how to plug your code in!*

---

## 1. What We Built & Why It Matters
We have successfully built and integrated a **Fully Automated Asynchronous Webhook Architecture** between our `.NET Backend` and our `Python FastAPI`.

### The Problem it Solves: The "Timeout of Death"
If our 4-Agent pipeline takes 2 to 5 minutes to evaluate a batch of CVs, a standard HTTP request from .NET to Python would timeout and crash after 30 seconds. This would kill the Python process midway, erasing all Agent data, and freezing the .NET server so no other users could access the system.

### The Solution: The Async Webhook
1. **The Drop-off:** `.NET` runs a Background Service that constantly looks for `Pending` applications. When it finds them, it drops them off at Python's API and *instantly hangs up* (Python returns a `202 Accepted`).
2. **Background Processing:** Python takes as much time as it needs (minutes or hours) to run the LangGraph Multi-Agent pipeline in the background.
3. **The Callback (Webhook):** When the AI finishes, Python initiates a brand new, secure POST request back to a special `.NET Webhook` endpoint, handing over the final JSON report to be saved in the PostgreSQL database.

This means **Zero Freezes, Zero Crashes, and 100% Autonomous Execution.**

---

## 2. Files We Edited
To make this architecture a reality, we modified the following key files:

**In .NET (`backend-dotnet`):**
- `appsettings.json` & `appsettings.Development.json`: Added a secure `Webhook:Secret`.
- `DTOs/WebhookEvaluationResultDto.cs`: Created a DTO to accept Python's final result.
- `Services/EvaluationTriggerService.cs`: Created the Background Service that automatically polls the DB for `Pending` students and triggers Python.
- `Program.cs`: Registered the new background service.
- `Controllers/ApplicationsController.cs`: Built the secure `/webhook/evaluation-result` endpoint for Python to call.

**In Python (`ai-service-python`):**
- `.env`: Added the `DOTNET_WEBHOOK_URL` and `WEBHOOK_SECRET`.
- `main.py`: Upgraded the endpoint to use FastAPI `BackgroundTasks`, added the `httpx` logic to trigger the .NET Webhook, and established the LangGraph orchestration.

---

## 3. How It Impacts The Team (The 4-Agent Flow)
This infrastructure is the "transport layer" that makes our 4-Agent dream a reality. Here is how everyone fits in:

* **Agent 1 (Planner) - *Rasal*:** You are the Head Chef. You look at the incoming data, define the plan, and tell the system what steps to execute next.
* **Agent 2 (Analysis/Scoring) - *RT*:** You are the Scorer. You analyze the student's CV against the job description and output a numerical score.
* **Agent 3 (Summary) - *Pasindu/Me*:** You are the Reviewer. If the student passes RT's score threshold, you write the detailed summary and evaluation report.
* **Agent 4 (Validation) - *Shanil*:** You are the Final QA. You ensure the final output is formatted perfectly before it is sent back to .NET.

---

## 4. The Filtering Logic
We do not want to waste expensive LLM tokens (or time) writing deep summaries for students who are completely unqualified. 

**Here is the flow:**
1. Agent 2 (RT) scores the candidate. 
2. If the score is **TOO LOW**, the pipeline stops early. We trigger the .NET Webhook with `IsSuccess: false` and a rejection message. .NET updates the DB to `Evaluation_Failed` (or rejected).
3. If the score is **HIGH ENOUGH**, the candidate is passed to Agent 3 (Pasindu) for a deep summary.
4. Once validated by Agent 4 (Shanil), Python triggers the .NET Webhook with `IsSuccess: true` and the JSON report. .NET updates the DB to `Agent_Evaluated`.

---

## 5. How to Connect Your Agents
All of the agents are stitched together using **LangGraph** inside `ai-service-python/main.py`.

### 🧠 The Shared Memory (`AgentState`)
You don't need to worry about HTTP requests or databases. All you need to do is read and write to the **Shared Memory** (the `AgentState` dictionary in `state.py`).
- When RT (Agent 2) finishes scoring, he saves the score to `state["score"]`.
- When Pasindu (Agent 3) starts, he simply reads `state["score"]` and writes to `state["summary"]`.

### 🔌 Plugging in your Code
Inside `main.py`, you will see mock nodes (e.g., `planner_node`, `action_node`). 
1. Write your LangChain/Gemini logic in your own file (e.g., `agents/planner.py`).
2. Import your function into `main.py`.
3. Replace the mock function inside `workflow.add_node("agent_name", your_function)`.

The Webhook logic is already perfectly wrapped around this graph. When the graph hits `END`, the infrastructure automatically takes your final `AgentState` and pushes it to .NET!

---

## 6. Alignment with the Original Plan
This architecture perfectly aligns with our original `README_AGENTS.md` design. We haven't changed the AI logic or the multi-agent strategy at all. What we did was build the **Production-Grade Engine** underneath it. 

The roads are paved, the webhook is listening, and the automated triggers are active. Now, all we have to do is drop our Agent scripts into the LangGraph nodes and watch the magic happen! Let's get building! 🚀
