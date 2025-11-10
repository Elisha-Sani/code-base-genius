# ⚙️ Codebase Genius Backend (BE)

The backend is built with **JacLang** and orchestrates the agent pipeline for code documentation.  
It exposes a **Jac server API** that accepts repository URLs and returns generated documentation.

---

## 📂 Structure
```
BE/
├── src/
│   ├── agents/
│   │   ├── mapper.jac       # RepoMapper agent
│   │   ├── analyzer.jac     # RepoAnalyzer agent
│   │   ├── genie.jac        # DocGenie agent
│   │   └── supervisor.jac   # CodeGenius orchestrator
│   ├── utils/
│   │   ├── parser.jac       # Git repo parser/cleanup
│   │   ├── rate_limiter.jac # LLM call limiter
│   │   └── __init__.jac
│   └── __init__.jac
├── requirements.txt         # Python deps for Jac server
├── .env.example             # Example environment variables
└── README.md                # Backend-specific readme
```

---

## 🔑 Environment Variables
Create a `.env` file in the project root:
```
GEMINI_API_KEY=your_api_key_here
```

---

## 🚀 Setup

### 1. Create a virtual environment
```bash
python3 -m venv venv
source venv/bin/activate   # Linux/Mac
venv\Scripts\activate      # Windows
```

### 2. Install dependencies
```bash
pip install -r requirements.txt
```

### 3. Run the Jac server
```bash
jac serve src/agents/supervisor.jac
```

---

## 🧭 Usage
Send a POST request:
```json
{
  "walker": "CodeGenius",
  "params": { "repo_url": "https://github.com/owner/repo" }
}
```

Docs will be generated under:
```
outputs/<repo_name>/docs.md
```

---

## 🛠 Notes
- Backend is stateless and portable.
- Error handling is layered (parser, agent, supervisor).
- Rate limiter ensures safe LLM usage.