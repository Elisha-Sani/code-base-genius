"""Streamlit frontend for Code Base Genius documentation generator."""

import streamlit as st
import requests
import time
import json

# Configure the page
st.set_page_config(
    page_title="Codebase Genius",
    page_icon="📚",
    layout="wide"
)

# Backend API configuration
API_BASE_URL = "http://localhost:8000"

def call_walker(walker_name: str, payload: dict) -> dict:
    """Call a Jac walker via the REST API."""
    url = f"{API_BASE_URL}/walker/{walker_name}"
    try:
        response = requests.post(url, json=payload, timeout=30)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        st.error(f"API Error: {str(e)}")
        return None

def initialize_session_state():
    """Initialize session state variables."""
    if "job_id" not in st.session_state:
        st.session_state.job_id = None
    if "status" not in st.session_state:
        st.session_state.status = None
    if "logs" not in st.session_state:
        st.session_state.logs = []
    if "markdown_content" not in st.session_state:
        st.session_state.markdown_content = None
    if "github_url" not in st.session_state:
        st.session_state.github_url = ""

def start_generation(github_url: str):
    """Start the documentation generation job."""
    with st.spinner("Starting documentation generation..."):
        result = call_walker("generate_docs", {"github_url": github_url})
        
        if result and "reports" in result and len(result["reports"]) > 0:
            report = result["reports"][0]
            st.session_state.job_id = report.get("job_id")
            st.session_state.status = report.get("status", "RUNNING")
            st.session_state.logs = []
            st.session_state.markdown_content = None
            st.success(f"Job started! Job ID: {st.session_state.job_id}")
        else:
            st.error("Failed to start job. Please try again.")

def poll_job_status():
    """Poll the job status and update session state."""
    if not st.session_state.job_id:
        return
    
    result = call_walker("get_job_status", {"job_id": st.session_state.job_id})
    
    if result and "reports" in result and len(result["reports"]) > 0:
        report = result["reports"][0]
        new_status = report.get("status", "UNKNOWN")
        
        # Update status
        if new_status in ["SUCCESS", "FAILURE", "COMPLETED"]:
            st.session_state.status = new_status
        elif new_status == "RUNNING":
            st.session_state.status = "RUNNING"
        else:
            st.session_state.status = new_status

def get_job_logs():
    """Fetch and return the latest job logs."""
    if not st.session_state.job_id:
        return []
    
    result = call_walker("get_job_logs", {"job_id": st.session_state.job_id})
    
    if result and "reports" in result and len(result["reports"]) > 0:
        report = result["reports"][0]
        return report.get("logs", [])
    return []

def get_job_result():
    """Fetch the final job result and markdown content."""
    if not st.session_state.job_id:
        return None
    
    result = call_walker("get_job_result", {"job_id": st.session_state.job_id})
    
    if result and "reports" in result and len(result["reports"]) > 0:
        report = result["reports"][0]
        if report.get("status") == "SUCCESS":
            return report.get("markdown_content")
        else:
            st.error(f"Error getting result: {report.get('message', 'Unknown error')}")
    return None

def main():
    """Main Streamlit application."""
    initialize_session_state()
    
    # Title and description
    st.title("Codebase Genius 📚")
    st.markdown("Generate comprehensive documentation from any GitHub repository")
    
    # Sidebar for configuration
    with st.sidebar:
        st.header("Settings")
        st.info("Backend API: " + API_BASE_URL)
        
        if st.button("Reset"):
            for key in list(st.session_state.keys()):
                del st.session_state[key]
            st.rerun()
    
    # Main input area
    col1, col2 = st.columns([3, 1])
    
    with col1:
        github_url = st.text_input(
            "GitHub Repository URL",
            value=st.session_state.github_url,
            placeholder="https://github.com/username/repository",
            help="Enter the full URL of the GitHub repository you want to document"
        )
        st.session_state.github_url = github_url
    
    with col2:
        st.write("")  # Spacing
        st.write("")  # Spacing
        generate_button = st.button(
            "Generate Documentation",
            type="primary",
            disabled=(not github_url or st.session_state.status == "RUNNING"),
            use_container_width=True
        )
    
    # Handle generate button click
    if generate_button and github_url:
        start_generation(github_url)
        st.rerun()
    
    # Display status and handle polling
    if st.session_state.status == "RUNNING":
        st.divider()
        st.subheader("📊 Generation Progress")
        
        # Create containers for dynamic updates
        status_container = st.empty()
        log_container = st.empty()
        
        # Polling loop
        max_polls = 200  # Maximum number of polls (10 minutes at 3s intervals)
        poll_count = 0
        
        while st.session_state.status == "RUNNING" and poll_count < max_polls:
            with status_container:
                st.info(f"🔄 Pipeline is running... (Poll {poll_count + 1})")
            
            # Update status
            poll_job_status()
            
            # Get and display logs
            logs = get_job_logs()
            if logs:
                st.session_state.logs = logs
                with log_container:
                    st.markdown("**Recent Logs:**")
                    log_text = "\n".join([
                        f"[{log.get('timestamp', 'N/A')}] {log.get('message', '')}"
                        for log in logs[-20:]  # Show last 20 logs
                    ])
                    st.code(log_text, language="log")
            
            # Check if status changed
            if st.session_state.status != "RUNNING":
                break
            
            # Wait before next poll
            time.sleep(3)
            poll_count += 1
        
        # Force a rerun to update UI
        if st.session_state.status != "RUNNING":
            st.rerun()
    
    # Display success result
    elif st.session_state.status in ["SUCCESS", "COMPLETED"]:
        st.divider()
        st.success("✅ Documentation generated successfully!")
        
        if st.session_state.markdown_content is None:
            with st.spinner("Fetching documentation..."):
                st.session_state.markdown_content = get_job_result()
        
        if st.session_state.markdown_content:
            st.subheader("📄 Generated Documentation")
            
            # Add download button
            st.download_button(
                label="Download Markdown",
                data=st.session_state.markdown_content,
                file_name="documentation.md",
                mime="text/markdown"
            )
            
            # Display the markdown content
            st.markdown("---")
            st.markdown(st.session_state.markdown_content)
        else:
            st.warning("Documentation was generated but content could not be retrieved.")
    
    # Display failure state
    elif st.session_state.status == "FAILURE":
        st.divider()
        st.error("❌ Documentation generation failed!")
        
        if st.session_state.logs:
            st.subheader("Error Logs")
            log_text = "\n".join([
                f"[{log.get('timestamp', 'N/A')}] {log.get('message', '')}"
                for log in st.session_state.logs
            ])
            st.code(log_text, language="log")
        
        st.info("Please check the logs above for details or try again with a different repository.")

if __name__ == "__main__":
    main()