#!/bin/bash

# This script expects two arguments: left path and right path
LEFT="$1"
RIGHT="$2"

# Launch Krusader with the given left and right paths
krusader --left="$LEFT" --right="$RIGHT"

