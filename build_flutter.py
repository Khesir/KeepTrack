#!/usr/bin/env python3
from pathlib import Path
from dotenv import dotenv_values
import argparse

# Default .env file
DOTENV_FILE = ".env"

# Platforms supported
PLATFORMS = ["android", "ios"]

# Load env vars from .env
def load_env(file_path):
    if not Path(file_path).exists():
        print(f"❌ {file_path} not found")
        exit(1)
    return dotenv_values(file_path)

def build_command(platform, env_file):
    env_vars = load_env(env_file)

    flutter_mode = env_vars.pop("FLUTTER_MODE", None)

    # Construct dart-define options with quotes for safe PowerShell use
    dart_defines = [f'--dart-define="{k}={v}"' for k, v in env_vars.items()]

    # Base flutter command
    if platform == "android":
        if flutter_mode is None:
            flutter_mode = "release"  # default for Android
        cmd = ["flutter", "build", "apk", f"--{flutter_mode}"] + dart_defines
    else:  # iOS
        # For iOS, do NOT use --release; flutter build ios defaults to release
        cmd = ["flutter", "build", "ios"] + dart_defines

    # Join into a single string for printing
    return " ".join(cmd)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Print Flutter build command using .env")
    parser.add_argument("platform", choices=PLATFORMS, help="Target platform")
    parser.add_argument("--env", default=DOTENV_FILE, help="Path to .env file")
    args = parser.parse_args()

    command = build_command(args.platform, args.env)
    print("\n🛠 Run the following command in your terminal:\n")
    print(command)
    print()
