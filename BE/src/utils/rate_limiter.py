"""
Rate limiter for Gemini API calls to prevent quota exhaustion.
Implements a token bucket algorithm with per-minute tracking.
"""
import time
from threading import Lock
from collections import deque
from typing import Optional

class RateLimiter:
    """Thread-safe rate limiter for API calls."""
    
    def __init__(self, calls_per_minute: int = 15, burst_size: int = 5):
        """
        Initialize rate limiter.
        
        Args:
            calls_per_minute: Maximum API calls allowed per minute
            burst_size: Maximum burst calls allowed (for brief spikes)
        """
        self.calls_per_minute = calls_per_minute
        self.burst_size = burst_size
        self.call_timestamps = deque(maxlen=calls_per_minute)
        self.lock = Lock()
        self.window_seconds = 60.0
        
    def _clean_old_timestamps(self):
        """Remove timestamps older than the time window."""
        current_time = time.time()
        cutoff_time = current_time - self.window_seconds
        
        while self.call_timestamps and self.call_timestamps[0] < cutoff_time:
            self.call_timestamps.popleft()
    
    def acquire(self, timeout: Optional[float] = None) -> bool:
        """
        Attempt to acquire permission for an API call.
        
        Args:
            timeout: Maximum seconds to wait (None = wait indefinitely)
            
        Returns:
            True if call is allowed, False if timeout exceeded
        """
        start_time = time.time()
        
        while True:
            with self.lock:
                self._clean_old_timestamps()
                
                # Check if we're under the limit
                if len(self.call_timestamps) < self.calls_per_minute:
                    self.call_timestamps.append(time.time())
                    return True
                
                # Check burst capacity
                recent_calls = sum(1 for ts in self.call_timestamps 
                                  if time.time() - ts < 10.0)
                if recent_calls >= self.burst_size:
                    # Calculate wait time
                    if self.call_timestamps:
                        oldest_timestamp = self.call_timestamps[0]
                        wait_time = self.window_seconds - (time.time() - oldest_timestamp)
                    else:
                        wait_time = 1.0
                else:
                    wait_time = 0.5
            
            # Check timeout
            if timeout is not None:
                elapsed = time.time() - start_time
                if elapsed >= timeout:
                    return False
                wait_time = min(wait_time, timeout - elapsed)
            
            # Wait before retrying
            time.sleep(max(0.1, wait_time))
    
    def get_stats(self) -> dict:
        """Get current rate limiter statistics."""
        with self.lock:
            self._clean_old_timestamps()
            return {
                "calls_in_window": len(self.call_timestamps),
                "calls_per_minute_limit": self.calls_per_minute,
                "available_calls": self.calls_per_minute - len(self.call_timestamps)
            }


# Global rate limiter instance for Gemini API
gemini_rate_limiter = RateLimiter(calls_per_minute=15, burst_size=5)


def rate_limited_call(func, *args, max_retries: int = 3, **kwargs):
    """
    Execute a function with rate limiting and retry logic.
    
    Args:
        func: Function to call (typically an LLM function)
        max_retries: Maximum retry attempts on failure
        *args, **kwargs: Arguments to pass to func
        
    Returns:
        Function result or error dict
    """
    for attempt in range(max_retries):
        # Acquire rate limit token
        if not gemini_rate_limiter.acquire(timeout=30.0):
            return {
                "error": "rate_limit_exceeded",
                "message": "Rate limit timeout after 30 seconds"
            }
        
        try:
            result = func(*args, **kwargs)
            
            # Check if result is an error dict
            if isinstance(result, dict) and "error" in result:
                if attempt < max_retries - 1:
                    wait_time = (attempt + 1) * 2  # Exponential backoff
                    print(f"LLM call failed, retrying in {wait_time}s... (attempt {attempt + 1}/{max_retries})")
                    time.sleep(wait_time)
                    continue
                return result
            
            return result
            
        except Exception as e:
            print(f"Exception in LLM call: {e}")
            if attempt < max_retries - 1:
                wait_time = (attempt + 1) * 2
                print(f"Retrying in {wait_time}s... (attempt {attempt + 1}/{max_retries})")
                time.sleep(wait_time)
            else:
                return {
                    "error": "execution_failed",
                    "message": str(e)
                }
    
    return {
        "error": "max_retries_exceeded",
        "message": f"Failed after {max_retries} attempts"
    }