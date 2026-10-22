#!/usr/bin/env bash
set -euo pipefail

mkdir -p addons
rm -rf addons/tau-plot addons/gdUnit4
cp -R vendor/tau-plot/addons/tau-plot addons/tau-plot
cp -R vendor/gdUnit4/addons/gdUnit4 addons/gdUnit4

test -f addons/tau-plot/plugin.cfg
test -f addons/gdUnit4/plugin.cfg
echo "Prepared TauPlot and GdUnit4 under res://addons/"
