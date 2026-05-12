#!/bin/bash
cd /Users/mohith/Downloads/yojana_mitra_app
echo "Starting BharatMitra UI revamp with Claude Code..."
claude --print "Read CLAUDE_UI_TASK.md and implement everything in it. Focus on lib/main.dart widget updates only. Keep all logic intact. Run flutter analyze when done."
