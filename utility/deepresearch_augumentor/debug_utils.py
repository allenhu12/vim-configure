import json
import logging
import os
import time
from datetime import datetime

# Set up logging
logger = logging.getLogger("reference_augmentor")

def save_debug_info(debug_info, extractor_type):
    # Create debug directory if it doesn't exist
    if not os.path.exists("debug"):
        os.makedirs("debug")
    
    # Save debug info to file
    debug_file = f"debug/debug_{extractor_type}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
    with open(debug_file, 'w', encoding="utf-8") as f:
        json.dump(debug_info, f, indent=2, ensure_ascii=False)
    print(f"Debug information saved to {debug_file}")
    return debug_file
