import sys
import os

def venv_status():
    """
    Checks if a Python virtual environment is active.
    Returns:
        (bool, str or None): (is_active, path_to_venv)
    """
    # Check via sys.prefix
    in_venv = (hasattr(sys, 'real_prefix') or 
               (hasattr(sys, 'base_prefix') and sys.base_prefix != sys.prefix))
    
    # Check via environment variable
    venv_path = os.environ.get("VIRTUAL_ENV")
    
    if in_venv:
        return True, venv_path or sys.prefix
    return False, None

# Example usage
active, path = venv_status()
if active:
    print(f"Virtual environment is active: {path}")
else:
    print("No virtual environment is active.")
# --- End of check-venv.py ---