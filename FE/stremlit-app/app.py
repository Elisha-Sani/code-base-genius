import streamlit as st
import requests
import time
from datetime import datetime

# --- 1. Configuration & Setup ---
BASE_URL = "http://localhost:8000"
GENERATE_DOCS_ENDPOINT = f"{BASE_URL}/walker/generate_docs"

st.set_page_config(
    page_title="Codebase Genius",
    page_icon="🧞",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Initialize session state keys
for key, default in {
    "documentation": None,
    "repo_name": None,
    "history": []
}.items():
    if key not in st.session_state:
        st.session_state[key] = default

# --- 2. Dark Theme CSS ---
st.markdown("""
    <style>
    body { background-color: #1f2937; color: #f9fafb; }
    h1, h2, h3 { color: #a5b4fc; }
    [data-testid="stSidebar"] { background-color: #111827; color: #f9fafb; }
    .stButton button {
        background-color: #4F46E5; color: #ffffff;
        border-radius: 6px; padding: 0.6rem 1rem; font-weight: 600;
        transition: 0.3s ease;
    }
    .stButton button:hover {
        background-color: #6366F1; color: #ffffff;
        transform: scale(1.02);
    }
    .history-item:hover {
        background-color: #374151; color: #f9fafb;
        border-radius: 8px; transition: 0.3s ease; padding-left: 4px;
    }
    input[type="text"] {
        background-color: #ffffff !important; color: #111827 !important;
        border-radius: 6px; padding: 0.5rem;
    }
    [data-testid="stForm"] {
        background-color: #111827;
        padding: 2rem;
        border-radius: 12px;
        box-shadow: 0 4px 12px rgba(0,0,0,0.4);
    }
    </style>
""", unsafe_allow_html=True)

# --- 3. Sidebar ---
with st.sidebar:
    st.image("https://cdn-icons-png.flaticon.com/512/6134/6134346.png", width=60)
    st.title("Codebase Genius")
    st.caption("AI-powered documentation generator")
    st.divider()

    st.subheader("🔗 Quick Links")
    st.page_link("https://github.com/Elisha-Sani/code-base-genius", label="Project GitHub Repo", icon="🤖")
    st.page_link("https://www.jac-lang.org/learn/examples/rag_chatbot", label="Jac + Streamlit Example", icon="🔗")
    st.page_link("https://www.jac-lang.org/", label="JacLang Homepage", icon="🚀")

    st.divider()
    st.subheader("🕓 Generation History")

    if not st.session_state.history:
        st.caption("Your generated docs will appear here.")
    else:
        for item in st.session_state.history:
            st.markdown(
                f"<div class='history-item'>📂 <b>{item['repo_name']}</b></div>",
                unsafe_allow_html=True
            )
            st.caption(f"{item['timestamp'].strftime('%Y-%m-%d %I:%M:%S %p')}")

# --- 4. Hero Section ---
st.markdown("""
    <div style="background:#1f2937;
                padding:2rem;border-radius:12px;text-align:center;
                border:1px solid #374151;">
        <h1 style="margin:0; color:#a5b4fc;">Welcome, Developer 👋</h1>
        <p style="font-size:1.2rem; color:#e5e7eb;">
            Turn any public GitHub repository into brilliant documentation.
        </p>
    </div>
""", unsafe_allow_html=True)

st.divider()

# --- 5. Input Form ---
col1, col2, col3 = st.columns([1, 2, 1])
with col2:
    with st.form("repo_form"):
        st.markdown("### 1. Enter Repository URL")
        repo_url = st.text_input(
            "Public GitHub URL",
            placeholder="https://github.com/username/repo",
            label_visibility="collapsed"
        )
        st.caption("Paste a valid public GitHub repository link.")
        submitted = st.form_submit_button("⚡ Generate Documentation", use_container_width=True)

# --- 6. Logic & Processing ---
if submitted and repo_url:
    st.session_state.documentation = None
    st.session_state.repo_name = None

    progress = st.progress(0)
    for pct in range(0, 101, 20):
        progress.progress(pct)
        time.sleep(0.1)

    with st.spinner("🤖 Agents at work... This may take a few minutes."):
        try:
            payload = {"repo_url": repo_url}
            response = requests.post(GENERATE_DOCS_ENDPOINT, json=payload)
            response.raise_for_status()
            result = response.json()

            if result.get("success"):
                generated_doc = result.get("report", [{}])[0]

                if isinstance(generated_doc, str):
                    st.session_state.documentation = generated_doc
                    st.session_state.repo_name = repo_url.rstrip("/").split("/")[-1]

                    st.session_state.history.insert(0, {
                        "repo_name": st.session_state.repo_name,
                        "timestamp": datetime.now()
                    })
                    st.success("✅ Documentation successfully generated!")

                elif isinstance(generated_doc, dict) and "error" in generated_doc:
                    st.error(f"Agent Error: {generated_doc['error']}")
                else:
                    st.error("Unexpected response format from the server.")
            else:
                st.error("The Jac walker did not complete successfully.")
                with st.expander("Debug Details"):
                    st.json(result)

        except requests.exceptions.RequestException:
            st.error(f"Connection Error: Could not connect to backend at `{GENERATE_DOCS_ENDPOINT}`.")

# --- 7. Results Display ---
if st.session_state.get("documentation"):
    st.divider()
    col_header, col_dl, col_copy = st.columns([4, 1, 1])

    with col_header:
        st.header(f"📘 Documentation: {st.session_state.repo_name}")
    with col_dl:
        st.download_button(
            label="⬇️ Download .md",
            data=st.session_state.documentation,
            file_name=f"{st.session_state.repo_name}_docs.md",
            mime="text/markdown",
            use_container_width=True
        )
    with col_copy:
        st.button("📋 Copy", use_container_width=True)

    tab1, tab2 = st.tabs(["📄 Rendered View", "📝 Raw Markdown"])

    with tab1:
        with st.container(height=600, border=True):
            st.markdown(st.session_state.documentation)

    with tab2:
        st.code(st.session_state.documentation, language="markdown", line_numbers=True)