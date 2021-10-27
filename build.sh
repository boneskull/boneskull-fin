#!/bin/bash

set -e
set -x

root="${1}"
file="${2}"
sources="${root}/src"
fileBasename=$(basename "${file}")
[[ $fileBasename == "lint_config.moon" ]] && exit
fileNoExt="${fileBasename%%.*}"

absoluteDir=$(dirname "${2}")
relativeDir=$(realpath --relative-to=${sources} ${absoluteDir})
outfile="${root}/${relativeDir}/${fileNoExt}.lua"
moonc -o "${outfile}" "${file}"
