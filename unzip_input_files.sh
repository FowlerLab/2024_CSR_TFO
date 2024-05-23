#!/bin/bash

## this script takes input files that were compressed for storage and distributionand unzips them

## requirements:
## none

## standard run command: sh unzip_input_files.sh

## ensure errors stop the process instead of powering through
set -e

## unzip all files
find . -name "*.gz" -exec gunzip -fv {} \;
