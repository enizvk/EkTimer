#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
"$PROJECT_DIR/Scripts/build.sh"
open "$PROJECT_DIR/EKTimer.app"
