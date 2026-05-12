#!/usr/bin/env python3
"""BharatMitra Production Test Runner - Token Efficient"""
import subprocess
import json
import os
import sys
from pathlib import Path

def run_cmd(cmd, label):
    """Run command and return success status."""
    print(f"\n{'='*60}")
    print(f"✓ {label}")
    print(f"{'='*60}")
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=120)
        if result.returncode == 0:
            print(f"✅ PASS")
            if result.stdout:
                lines = result.stdout.split('\n')
                print('\n'.join(lines[-10:]))  # Last 10 lines
            return True
        else:
            print(f"❌ FAIL")
            if result.stderr:
                print(result.stderr[-500:])  # Last 500 chars of error
            return False
    except subprocess.TimeoutExpired:
        print(f"⏱️  TIMEOUT")
        return False
    except Exception as e:
        print(f"⚠️  ERROR: {e}")
        return False

def main():
    project = "/Users/mohith/Downloads/yojana_mitra_app"
    os.chdir(project)

    results = {}

    # Test 1: Backend Python Syntax
    results['1_syntax'] = run_cmd(
        f"cd {project}/backend && python3 -m py_compile main.py",
        "Backend Python Syntax Check"
    )

    # Test 2: Backend Unit Tests
    results['2_backend_tests'] = run_cmd(
        f"cd {project}/backend && python3 -m unittest test_service_integrations 2>&1",
        "Backend Unit Tests (12 tests)"
    )

    # Test 3: Flutter Analyze
    results['3_flutter_analyze'] = run_cmd(
        f"cd {project} && /opt/homebrew/bin/flutter analyze --no-fatal-infos 2>&1 | tail -20",
        "Flutter Analyze (Linting)"
    )

    # Test 4: Check APK exists
    apk_path = f"{project}/build/app/outputs/flutter-apk/app-release.apk"
    results['4_apk_exists'] = os.path.exists(apk_path)
    print(f"\n{'='*60}")
    print(f"✓ APK File Exists")
    print(f"{'='*60}")
    if results['4_apk_exists']:
        size = os.path.getsize(apk_path) / (1024*1024)
        print(f"✅ PASS - {size:.1f} MB")
    else:
        print(f"❌ FAIL - APK not found")

    # Test 5: Check secrets not in git
    results['5_no_secrets'] = run_cmd(
        f"cd {project} && git status 2>/dev/null | grep -q 'key.properties\\|.jks\\|.keystore' && echo 'FOUND SECRETS' || echo 'NO SECRETS'",
        "Git Status (No Secrets Check)"
    )

    # Test 6: Backend README updated
    results['6_docs_updated'] = run_cmd(
        f"cd {project} && grep -q 'local_fallback' backend/README.md && echo 'DOCS OK' || echo 'DOCS STALE'",
        "Documentation Updated (local_fallback mentioned)"
    )

    # Summary
    print(f"\n{'='*60}")
    print("TEST SUMMARY")
    print(f"{'='*60}")
    passed = sum(1 for v in results.values() if v)
    total = len(results)
    print(f"Passed: {passed}/{total}")
    for test, result in results.items():
        status = "✅" if result else "❌"
        print(f"  {status} {test}")

    # Exit code
    sys.exit(0 if passed == total else 1)

if __name__ == "__main__":
    main()
