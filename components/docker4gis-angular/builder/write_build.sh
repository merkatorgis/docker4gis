#!/bin/bash
set -euxo pipefail

# Find the first outputPath in angular.json
projects="require('./angular.json').projects"
project="Object.values($projects)[0]"
outputPathQuery="$project.architect.build.options.outputPath"
outputPath=$(node --print "$outputPathQuery")

# Angular can omit outputPath and use dist/<name> by default.
if [ -z "$outputPath" ] || [ "$outputPath" = "undefined" ] || [ "$outputPath" = "null" ]; then
    appName=$(node --print "Object.keys($projects)[0]")
    outputPath="dist/$appName"
fi

dist=$outputPath
if [ -d "$outputPath/browser" ]; then
    dist+=/browser
fi
mv "$dist" "$BUILD_DESTINATION"

if [ -d "$outputPath/assets" ]; then
    cp -r "$outputPath/assets"/* "$BUILD_DESTINATION"/
fi
