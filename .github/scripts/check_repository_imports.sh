#!/usr/bin/env bash
# Enforces the repository layer boundary: cloud_firestore and firebase_storage
# may only be imported inside lib/repositories/firebase/ or firebase_providers.dart.
set -euo pipefail

ALLOWED="stanag_app/lib/repositories/firebase/\|stanag_app/lib/providers/firebase_providers.dart"

violations=$(grep -rl \
  --include="*.dart" \
  -e "package:cloud_firestore/" \
  -e "package:firebase_storage/" \
  stanag_app/lib/ \
  | grep -v "$ALLOWED" || true)

if [ -n "$violations" ]; then
  echo "Direct Firebase SDK imports found outside the repository layer:"
  echo "$violations"
  echo ""
  echo "Allowed locations:"
  echo "  stanag_app/lib/repositories/firebase/"
  echo "  stanag_app/lib/providers/firebase_providers.dart"
  exit 1
fi

echo "No direct Firebase SDK imports outside the repository layer."
