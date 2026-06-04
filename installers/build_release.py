import re
import subprocess
import sys
import os

FRONTEND_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INSTALLERS_DIR = os.path.dirname(os.path.abspath(__file__))
ISS_SCRIPT = os.path.join(INSTALLERS_DIR, "desktop_inno_script.iss")
ISCC = r"C:\Program Files (x86)\Inno Setup 6\ISCC.exe"

PRODUCTION_OVERRIDES = {
    "API_BASE_URL": "https://keep-track-backend.vercel.app/api/v1",
}


def get_version() -> str:
    pubspec = os.path.join(FRONTEND_DIR, "pubspec.yaml")
    with open(pubspec) as f:
        for line in f:
            match = re.match(r"^version:\s*(\d+\.\d+\.\d+)", line)
            if match:
                return match.group(1)
    raise RuntimeError("Could not find version in pubspec.yaml")


def sync_iss_version(version: str):
    with open(ISS_SCRIPT) as f:
        content = f.read()
    content = re.sub(r'(#define MyAppVersion\s+")[^"]*(")', rf'\g<1>{version}\2', content)
    content = re.sub(r'(OutputBaseFilename=KeepTrack-v)[^\n]*', rf'\g<1>{version}', content)
    with open(ISS_SCRIPT, "w") as f:
        f.write(content)
    print(f"ISS version synced to {version}")


def load_env() -> dict[str, str]:
    env_file = os.path.join(FRONTEND_DIR, ".env")
    env = {}
    with open(env_file) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, _, value = line.partition("=")
            env[key.strip()] = value.strip()
    env.update(PRODUCTION_OVERRIDES)
    return env


def dart_defines(env: dict[str, str]) -> list[str]:
    return [f"--dart-define={k}={v}" for k, v in env.items()]


def run(cmd: list[str], cwd: str = FRONTEND_DIR):
    print(f"\n> {' '.join(cmd)}")
    result = subprocess.run(cmd, cwd=cwd, shell=True)
    if result.returncode != 0:
        print(f"Command failed with exit code {result.returncode}")
        sys.exit(result.returncode)


def build_windows(defines: list[str]):
    print("\n=== Building Windows release ===")
    run(["flutter", "clean"])
    run(["flutter", "pub", "get"])
    run(["flutter", "build", "windows", "--release"] + defines)
    print("Windows build complete: build/windows/x64/runner/Release/")

    if not os.path.exists(ISCC):
        print(f"Inno Setup not found at {ISCC} — skipping installer compilation.")
        return

    print("\n=== Compiling Inno Setup installer ===")
    run([ISCC, ISS_SCRIPT])
    print(f"Installer output: {INSTALLERS_DIR}")


def build_apk(defines: list[str], version: str):
    print("\n=== Building Android APK release ===")
    run(["flutter", "clean"])
    run(["flutter", "pub", "get"])
    run(["flutter", "build", "apk", "--release"] + defines)

    src = os.path.join(FRONTEND_DIR, "build", "app", "outputs", "flutter-apk", "app-release.apk")
    dst = os.path.join(FRONTEND_DIR, "build", "app", "outputs", "flutter-apk", f"KeepTrack-v{version}.apk")
    if os.path.exists(src):
        os.rename(src, dst)
        print(f"APK build complete: {dst}")
    else:
        print("APK build complete (output file not found to rename)")


def main():
    targets = sys.argv[1:] or ["windows", "apk"]

    version = get_version()
    print(f"Version: {version}")

    sync_iss_version(version)

    env = load_env()
    defines = dart_defines(env)
    print("Loaded env vars:", list(env.keys()))

    if "windows" in targets:
        build_windows(defines)

    if "apk" in targets:
        build_apk(defines, version)

    print("\nAll builds complete.")


if __name__ == "__main__":
    main()
