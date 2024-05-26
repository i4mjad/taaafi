#!/bin/bash

# Navigate to the src directory where your Angular project's files are located
cd src

# Find all .css files and rename them to .scss
find . -name "*.css" -exec bash -c 'mv "$0" "${0%.css}.scss"' {} \;

echo "All CSS files have been renamed to SCSS."