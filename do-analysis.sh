#!/bin/bash

BUILD_DIR="./before"
REPORT_DIR="./analysis-reports/clang-tidy"

mkdir -p "$REPORT_DIR"

find $BUILD_DIR \( -name "*.c" -o -name "*.cpp" -o -name "*.cc" \) | while read file; do
    echo ">> Analyzing $file ..."
    report_file="$REPORT_DIR/$(echo $file | tr '/' '_').txt"
    clang-tidy "$file" \
        --quiet \
        -header-filter=.* \
        -p "$BUILD_DIR" \
        -- \
        -std=c99 \
        -Os \
        -fomit-frame-pointer \
        -D_GNU_SOURCE \
        -I./libcommon -I./libuxre \
        -DUXRE \
        -D_FILE_OFFSET_BITS=64L \
        > "$report_file"
done

echo "Analysis complete. Reports are in $REPORT_DIR"

echo "Run cppcheck..."
cppcheck --enable=all --inconclusive --std=c99 . &> "./analysis-reports/cppcheck_all.txt"
