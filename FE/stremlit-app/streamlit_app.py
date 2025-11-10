"""Streamlit frontend for Code Base Genius documentation generator."""

import streamlit as st
import requests
import time
from datetime import datetime, timezone
from pathlib import Path
from dotenv import load_dotenv
import os

# Load environment variables from .env file in the same directory as this script
env_path = Path(__file__).parent / '.env'
load_dotenv(dotenv_path=env_path)

# Configure the page
st.set_page_config(
    page_title="Codebase Genius",
    page_icon="📚",
    layout="wide"
)

# Backend API configuration
API_BASE_URL = os.getenv("API_BASE_URL", "http://localhost:8000")
CURRENT_USER = os.getenv("GITHUB_USER", "Elisha-Sani")

def get_current_utc():
    """Get current UTC time in YYYY-MM-DD HH:MM:SS format."""
    return datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S")

def initialize_session_state():
    """Initialize session state variables."""
    if "job_id" not in st.session_state:
        st.session_state.job_id = None
    if "pipeline_status" not in st.session_state:
        st.session_state.pipeline_status = None
    if "documentation" not in st.session_state:
        st.session_state.documentation = None
    if "repo_url" not in st.session_state:
        st.session_state.repo_url = ""
    if "error" not in st.session_state:
        st.session_state.error = None

def render_sidebar():
    """Render the sidebar with configuration and status."""
    with st.sidebar:
        st.header("⚙️ Configuration")
        st.info(f"Backend API: {API_BASE_URL}")
        
        # System Information
        st.divider()
        st.subheader("🖥️ System Info")
        
        # Current UTC time with auto-refresh
        st.markdown(f"**Current UTC Time:**\n```\n{get_current_utc()}\n```")
            
        # Current user
        st.markdown(f"**Current User:**\n```\n{CURRENT_USER}\n```")
        
        if st.session_state.job_id:
            st.divider()
            st.subheader("🔄 Current Job")
            st.code(st.session_state.job_id)
            
            if st.button("Reset Session", type="secondary"):
                for key in list(st.session_state.keys()):
                    del st.session_state[key]
                st.rerun()

def validate_github_url(url: str) -> bool:
    """Validate GitHub repository URL format."""
    import re
    pattern = r'^https?://github\.com/[\w.-]+/[\w.-]+/?$'
    return bool(re.match(pattern, url))

def render_input_form():
    """Render the main input form."""
    st.title("📚 Codebase Genius")
    st.markdown("Generate comprehensive documentation from any GitHub repository")
    
    # Create form
    with st.form(key="repo_form"):
        repo_url = st.text_input(
            "GitHub Repository URL",
            value=st.session_state.repo_url,
            placeholder="https://github.com/username/repository",
            help="Enter the full URL of the GitHub repository you want to document"
        )
        
        # Validation message
        if repo_url and not validate_github_url(repo_url):
            st.error("Please enter a valid GitHub repository URL")
        
        # Submit button - fixed the parameters
        submit_disabled = st.session_state.job_id is not None or (repo_url and not validate_github_url(repo_url))
        submitted = st.form_submit_button(
            label="Generate Documentation",
            disabled=submit_disabled,
            use_container_width=True
        )
        
        # Handle form submission
        if submitted and repo_url and validate_github_url(repo_url):
            st.session_state.repo_url = repo_url
            try:
                # Your API call logic here
                st.session_state.job_id = "test_job_id"  # Replace with actual API call
                st.session_state.pipeline_status = "RUNNING"
                st.session_state.error = None
                st.rerun()
            except Exception as e:
                st.session_state.error = str(e)

def main():
    """Main Streamlit application."""
    initialize_session_state()
    render_sidebar()
    
    if st.session_state.error:
        st.error(st.session_state.error)
    
    render_input_form()

if __name__ == "__main__":
    main()