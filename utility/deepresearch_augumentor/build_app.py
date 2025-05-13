#!/usr/bin/env python3
"""
Build script for packaging Reference Augmentor with PyInstaller.

Usage:
    python build_app.py [--onefile]
"""

import os
import sys
import argparse
import subprocess
import platform

def check_requirements():
    """Check if PyInstaller is installed."""
    try:
        import PyInstaller
        print("PyInstaller is already installed.")
    except ImportError:
        print("Installing PyInstaller...")
        subprocess.check_call([sys.executable, "-m", "pip", "install", "pyinstaller"])
        print("PyInstaller installed successfully.")

def build_app(one_file=False):
    """Build the application with PyInstaller."""
    # Determine the output name based on the platform
    if platform.system() == "Windows":
        output_name = "ReferenceAugmentor.exe"
    else:
        output_name = "ReferenceAugmentor"
    
    # Basic PyInstaller command
    cmd = [
        "pyinstaller",
        "--name", "ReferenceAugmentor",
        "--add-data", "extractors:extractors",
    ]
    
    # Add --onefile if requested
    if one_file:
        cmd.append("--onefile")
    else:
        cmd.append("--onedir")
    
    # Add main script and other modules
    cmd.extend([
        "main.py",
        "config_manager.py",
    ])
    
    # Execute PyInstaller
    print(f"Building {'single file executable' if one_file else 'directory'} with PyInstaller...")
    subprocess.check_call(cmd)
    
    # Report success
    dist_path = os.path.join("dist", "ReferenceAugmentor")
    if one_file:
        print(f"Single file executable built at: {dist_path}")
    else:
        print(f"Application directory built at: {dist_path}")
    
    # Print usage instructions
    print("\nTo use the packaged application:")
    if platform.system() == "Windows":
        if one_file:
            print("  ReferenceAugmentor.exe --usage")
        else:
            print("  dist\\ReferenceAugmentor\\ReferenceAugmentor.exe --usage")
    else:
        if one_file:
            print("  ./ReferenceAugmentor --usage")
        else:
            print("  ./dist/ReferenceAugmentor/ReferenceAugmentor --usage")
    
    # Note about API keys
    print("\nIMPORTANT: You'll need to set API keys before using the extractors:")
    if platform.system() == "Windows":
        if one_file:
            print("  ReferenceAugmentor.exe --set-jina-key YOUR_JINA_API_KEY")
        else:
            print("  dist\\ReferenceAugmentor\\ReferenceAugmentor.exe --set-jina-key YOUR_JINA_API_KEY")
    else:
        if one_file:
            print("  ./ReferenceAugmentor --set-jina-key YOUR_JINA_API_KEY")
        else:
            print("  ./dist/ReferenceAugmentor/ReferenceAugmentor --set-jina-key YOUR_JINA_API_KEY")

def main():
    """Parse arguments and build the application."""
    parser = argparse.ArgumentParser(description="Build Reference Augmentor with PyInstaller")
    parser.add_argument("--onefile", action="store_true", help="Build a single executable file")
    args = parser.parse_args()
    
    # Check requirements
    check_requirements()
    
    # Build the application
    build_app(args.onefile)

if __name__ == "__main__":
    main() 