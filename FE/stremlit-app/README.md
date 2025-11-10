# 🎨 Codebase Genius Frontend (FE)

The frontend is a **Streamlit app** that provides a user‑friendly interface for triggering documentation generation and visualizing outputs.  
It is optimized for **dark mode**, **high‑contrast text**, and **accessible design**.

---

## 📂 Structure
```
FE/stremlit-app/
├── app.py             # Main Streamlit entry point
├── components/        # UI components
├── pages/             # Multi-page Streamlit views
├── assets/            # Static assets (icons, styles)
└── README.md          # Frontend-specific readme
```

---

## 🚀 Setup

### 1. Install dependencies
```bash
pip install -r requirements.txt
```

### 2. Run the Streamlit app
```bash
streamlit run app.py
```

---

## 🧭 Usage
- Enter a GitHub repository URL in the UI.
- Trigger documentation generation via the backend API.
- View generated outputs:
  - 📊 Repo statistics
  - 🌳 File tree explorer
  - 📝 Markdown documentation
  - 🖼 Mermaid diagrams

---

## 🎨 Accessibility
- Locked **dark mode** for visual comfort.
- **High‑contrast text** for readability.
- **Accessible design system** with keyboard navigation and screen reader support.

---

## 🛠 Notes
- Frontend communicates with backend via REST API.
- Error boundaries ensure resilient user experience.
- Designed for iterative troubleshooting and workflow hygiene.