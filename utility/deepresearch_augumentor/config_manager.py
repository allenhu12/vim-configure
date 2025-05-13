import os
import json
from pathlib import Path

class ConfigManager:
    def __init__(self, app_name="ReferenceAugmentor"):
        # Get the appropriate config directory based on OS
        if os.name == 'nt':  # Windows
            config_dir = os.path.join(os.environ['APPDATA'], app_name)
        else:  # macOS/Linux
            config_dir = os.path.join(str(Path.home()), f".{app_name.lower()}")
        
        # Ensure directory exists
        os.makedirs(config_dir, exist_ok=True)
        
        self.config_file = os.path.join(config_dir, "config.json")
        self.config = self._load_config()
    
    def _load_config(self):
        """Load configuration from file or create default if not exists"""
        if os.path.exists(self.config_file):
            try:
                with open(self.config_file, 'r') as f:
                    return json.load(f)
            except Exception:
                return {}
        return {}
    
    def _save_config(self):
        """Save configuration to file"""
        with open(self.config_file, 'w') as f:
            json.dump(self.config, f)
        
        # Set appropriate file permissions on Unix-like systems
        if os.name != 'nt':
            import stat
            os.chmod(self.config_file, stat.S_IRUSR | stat.S_IWUSR)  # User read/write only
    
    def get_api_key(self, key_name):
        """Get API key, returning None if not found"""
        return self.config.get(key_name)
    
    def set_api_key(self, key_name, value):
        """Set API key"""
        self.config[key_name] = value
        self._save_config()
        return True
    
    def clear_api_key(self, key_name):
        """Remove an API key from the config"""
        if key_name in self.config:
            del self.config[key_name]
            self._save_config()
            return True
        return False 