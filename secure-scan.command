#!/bin/bash
# Dwuklik w Finderze uruchamia skan i otwiera dashboard.
# Double-click in Finder to run the scan and open the dashboard.
cd "$(dirname "$0")" || exit 1
./secure-scan.sh
echo ""
echo "Naciśnij Enter aby zamknąć / Press Enter to close…"
read -r _
