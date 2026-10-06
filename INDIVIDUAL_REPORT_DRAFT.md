# Individual Report: Component C (IT24100316)
Evaluation & Summary Engine + Action Agent

## 1. Contribution Statement
As a core developer for the Campus Placement System, I took full ownership of Component C: Evaluation & Summary Engine alongside the intelligent Action Agent. My contributions were critical in establishing a robust application lifecycle pipeline that allows students to track applications and leverages generative AI to dynamically summarize evaluations for HR personnel. I implemented solutions across the entire technology stack—spanning the PostgreSQL database schema, the ASP.NET Core backend API, the Python LangGraph microservice, the React web dashboard for staff, and the Flutter mobile application for students. My work ensured that the AI integration was not only functionally complete but also architecturally sound, seamlessly integrating human-in-the-loop approvals with automated AI processing.

## 2. Owned Component and Technical Work
My technical responsibilities encompassed the complete vertical slice of the Application Lifecycle and AI Evaluation domains. Below are the specific technical assets I designed, developed, and maintained:

**Web Frontend (React)**
•	`frontend-react/src/pages/ApplicationsPage.tsx`: Built the primary dashboard for university staff to manage, review, and approve or reject student applications.
•	`frontend-react/src/components/admin/InternalMemosPanel.jsx`: Engineered a custom slide-out panel allowing HR and admins to attach, view, and resolve internal notes (memos) as a strict blocker before approval.
•	`frontend-react/src/pages/HrLandingPage.tsx`: Maintained the inbox UI on the Company HR Dashboard, displaying applicant cards populated with dynamic Match Scores and readable AI Evaluation Summaries.

**Mobile Frontend (Flutter)**
•	`frontend_flutter/lib/features/applications/presentation/screens/applications_tracking_screen.dart`: Developed the main tracking screen empowering students to view their application lifecycle, real-time Match Score, and action pending interview requests.
•	`frontend_flutter/lib/core/services/api_service.dart`: Handled API communication, developing the specific methods (`getApplications()`, `acceptOffer()`) for state synchronization with the .NET backend.

**Backend API (.NET)**
•	`backend-dotnet/Controllers/ApplicationsController.cs`: Designed RESTful API endpoints for applying to jobs, processing staff approvals (`AdminApprove`), and receiving AI evaluation payloads (`ReceiveEvaluationResult`).
•	`backend-dotnet/Controllers/MemosController.cs`: Engineered the API endpoints for managing internal staff memos tied to specific applications.
•	`backend-dotnet/Services/ApplicationService.cs`: Implemented the core business logic governing complex application state transitions (e.g., `AdminDecisionAsync`, `StudentDecisionAsync`).
•	`backend-dotnet/DTOs/WebhookEvaluationResultDto.cs` & `CreateMemoDto.cs`: Created strict Data Transfer Objects to ensure secure parsing of Python AI payloads and memo creation.
•	Database (EF Core/PostgreSQL): Owned the `Applications` and `Memos` entities, specifically managing the `SummaryReport` as a PostgreSQL `jsonb` column for unstructured AI output.

**AI Service (Python LangGraph Agent)**
•	`ai-service-python/main.py`: Developed the FastAPI orchestration endpoints, specifically the `/resume` webhook to wake up the agent after human approval.
•	`ai-service-python/agents/action/action_node.py` & `action_service.py`: Coded the Recommendation Engine (Agent 3 - The Action Agent) that consumes parsed analysis data to generate a strict, non-hallucinated 3-Point Final Recommendation Summary for recruiters.
•	`ai-service-python/tools/github_tool.py`: Engineered a custom tool to programmatically fetch and parse student GitHub repository data to provide real-world coding context to the Action Agent.
•	LangGraph Orchestration (`ai-service-python/state.py`): Designed the graph state transitions to handle the human-in-the-loop pause, seamlessly pausing execution until a staff member resolves memos and approves the candidate.

## 3. Key Commit, Pull-Request, and Test Evidence
Throughout the development cycle, I maintained a clean and descriptive version control history on GitHub. My primary commits are concentrated in the `Candidate profile & application engine` and `Evaluation & summary engine` branches. 

Key evidence of my contributions includes:
•	**Git Commits:** Commits such as *"Integrate FastAPI Action Agent with ApplicationsController"* and *"Fix Application JSONB serialization for AI output"* demonstrate my work in ensuring reliable AI data persistence and orchestration.
•	**Testing:** I wrote specific unit and integration tests focusing on the .NET-to-FastAPI handoff. This ensured that webhooks triggered correctly and that failure states were caught and handled gracefully by the C# backend.
•	**API Documentation:** Documented the application endpoints via Swagger/OpenAPI, explicitly defining the DTO schemas required for cross-service communication.

## 4. Challenges and Learning
One of the most significant challenges was developing the Action Agent to reliably evaluate complex student CVs against rigid job requirements without hallucinating. Standard LLM calls would often generate conversational text or return inconsistently formatted responses. Overcoming this required advanced prompt engineering, injecting structured few-shot examples, and implementing strict Pydantic output parsers in Python. This forced the AI to return a clean, deterministic 3-point recommendation summary that the React frontend could render flawlessly.

Another major hurdle was the serialization and parsing of complex `JSONB` data between the .NET backend and the Python AI service. The C# strongly-typed ecosystem often clashed with Python's dynamic JSON outputs, leading to parsing errors. I learned to enforce strict Pydantic schemas on the Python side to guarantee that the JSON payload matched the expected C# DTOs exactly.

A highly unique challenge I undertook was the design and implementation of a custom `github_tool` for the Action Agent. I wanted the AI to go beyond simply parsing PDF resumes by allowing it to programmatically fetch and analyze a student's actual GitHub repositories. Integrating the GitHub API securely, managing rate limits, and parsing raw repository data (like commit history and languages used) into a concise context window for the LLM proved incredibly difficult. However, successfully building this tool taught me how to extend an AI agent's capabilities with real-world REST API integrations, making our final candidate evaluations vastly more accurate and data-driven.

On the frontend, integrating the internal Memo feature into the React state proved challenging. Ensuring that a "Pending" memo instantly disabled the "Approve" button across the `ApplicationsPage` required careful lifting of state and `useEffect` dependency management. Finally, refining the Action Agent to generate strict, non-hallucinated 3-point recommendation summaries taught me advanced prompt engineering, heavily utilizing output parsers and strict system constraints to force the LLM to adhere to the HR formatting standards.

## 5. Individual AI Usage Log

| AI Tool/Model | Task | What it Produced | What You Changed/Rejected | How You Verified It |
| :--- | :--- | :--- | :--- | :--- |
| GPT-4o | LangGraph Node Structuring | Generated the initial Python graph states and edges for the Action Agent. | The AI's graph structure didn't account for asynchronous API timeouts. I rewrote the edge logic to gracefully handle backend disconnections. | Traced the graph execution locally using LangSmith to ensure state transitions worked perfectly. |
| Claude 3.5 Sonnet | Refined AI Evaluation Prompts | Provided a massive system prompt for generating the 3-point recommendation summary. | The prompt was too verbose and caused token limit issues. I stripped it down and injected a strict JSON schema requirement. | Pushed mock CVs through the `/webhook/evaluation-result` endpoint and validated the JSON payloads. |
| GPT-4o | C# Webhook Integration | Scaffolded the `ApplicationsController` endpoint to receive the Python AI results. | The AI suggested using dynamic types for the payload. I explicitly created strict `WebhookEvaluationResultDto` classes to guarantee data integrity. | Inspected the PostgreSQL `jsonb` column to confirm the AI's structured data mapped correctly. |
| Claude 3.5 Sonnet | UI for AI Summary Rendering | Generated the React cards to display the AI's 3-point summary in the HR Dashboard. | The CSS lacked responsiveness for varying AI text lengths. I manually implemented custom Tailwind flex layouts. | Resized the browser window and verified the UI didn't break on varying AI output sizes. |

## 6. AI Reflection
Using generative AI throughout this project completely shifted my development workflow. Rather than spending hours writing boilerplate UI code or basic API boilerplate, I was able to generate foundational structures in seconds. However, this shift meant my primary role became managing complex API contracts and LangGraph state management. I spent the majority of my time architecting *how* the AI-generated components talked to each other.

The project highlighted the critical importance of strict validation when dealing with LLM outputs. When generating HR recommendation summaries, I quickly learned that AI models are unpredictable. Relying on an LLM to generate UI-ready text requires enforcing rigid schemas (like forcing JSON responses) and writing defensive backend code to handle unexpected formatting. This experience taught me that AI is an incredible accelerator, but the engineer's role is to build the guardrails that make the AI's output safe, predictable, and production-ready.

## 7. Signed Declaration
I, **Weerasingha P.M.P.L.**, hereby declare that the work and code presented in this report and the associated repository are my own original work, except where explicitly stated otherwise or generated through the acknowledged use of AI assistance as detailed in the AI Usage Log.

**Date:** October 6, 2026
