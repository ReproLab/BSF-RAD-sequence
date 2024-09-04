#!/bin/bash

# DESCRIPTION
#
# This tool identifies any files that were not downloaded properly from GC3F.
# 
# It does so by comparing, for each file, a locally computed MD5sum with an
# MD5sum computed on our upstream computer. If the two MD5sums do not match, that
# indicates that the download failed for that file, and that file needs to be
# downloaded again.
#
# USAGE
#
# You can run this tool from any location, and it will work correctly. Here are
# a few examples of ways you can run this tool:
#
# INFO/check_downloads.sh
# ./check_downloads.sh
#
# bash INFO/check_downloads.sh
# bash check_downloads.sh
#
# Genomics & Cell Characterization Core Facility (GC3F)
# Jason Sydes

echo "--- THIS TOOL IS BETA ---"
echo "This is a new tool to identify files that were not downloaded correctly." 
echo "Please report any problems using or running this tool to genomics@uoregon.edu."
echo "--- THIS TOOL IS BETA ---"
echo

# Counts
TOTAL_FILES_COUNT=0
GOOD_FILES_COUNT=0
BAD_FILES_COUNT=0

# Get PATHS
INFO_FOLDER_PATH=$(dirname $(realpath $0))
EXECUTION_PATH=$(dirname $INFO_FOLDER_PATH)

# Execute this script from the top-level sequencing folder.
cd $EXECUTION_PATH

# Error out if INFO/md5sums.txt does not exist
if [ ! -e INFO/md5sums.txt ] ; then 
    echo ERROR: Cannot continue, could not find INFO/md5sums.txt. Exiting.
    exit 1
fi

# Use the local version of the md5sum tool.
if [ `which md5sum` ] ; then 
    # Linux systems
    MD5_TOOL=md5sum
elif [ `which md5sum-lite` ] ; then 
    # MacOS systems
    MD5_TOOL=md5sum-lite
else
    echo "ERROR: Could not find md5sum executable (couldn't find 'md5sum' or 'md5sum-lite'). Exiting."
    exit 1
fi

echo
echo NOTICE: Computing md5sums is non-trivial. Please be patient, this will take some time.
echo

# Run md5 on downloaded files, compare to upstream md5 fingerprints, look for mismatches.
while read md5_source filename; do
    ((TOTAL_FILES_COUNT+=1))
    echo -n "checking $filename ... "
    md5_local=$($MD5_TOOL $filename | awk '{print $1}')
    if [ "$md5_local" = "$md5_source" ] ; then 
        ((GOOD_FILES_COUNT+=1))
        GOOD_FILES="$GOOD_FILES $filename"
        echo "good."
    else
        ((BAD_FILES_COUNT+=1))
        BAD_FILES="$BAD_FILES $filename"
        echo "bad, md5sum mismatch. Source md5sum: $md5_source ; Local md5sum: $md5_local"
    fi
done < INFO/md5sums.txt

# Report any errors.
if [ "$BAD_FILES" != "" ] ; then 
    echo
    echo "ERROR: The following files did not download correctly, please download them again:"
    for bad_file in $BAD_FILES; do
        echo $bad_file
    done
    echo
fi

# Report a summary.
echo
echo SUMMARY
echo $TOTAL_FILES_COUNT total files.
echo $GOOD_FILES_COUNT good files.
echo $BAD_FILES_COUNT files with mismatched md5sums.
echo
