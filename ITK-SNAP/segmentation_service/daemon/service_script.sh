#!/bin/bash
set -x

# Look up the git commit hash of the service SegmentationCall (third word in output)
GITHASH=$(itksnap-wt -P -dssp-services-list | grep SegmentationCall | awk '{print $3}')

# Temporary directory for this script
if [[ ! $TMPDIR ]]; then
  TMPDIR=./work/service_${GITHASH}
  mkdir -p $TMPDIR
fi

# Run in an infinite loop
while [[ true ]]; do

  # Claim a ticket
  itksnap-wt -dssp-services-claim $GITHASH testlab instance_1 > $TMPDIR/claim.txt

  # If return code is non-zero we sleep and continue
  if [[ $? -ne 0 ]]; then
    sleep 10
    continue
  fi

  # Get the ticket id (second word in line starting with '1>')
  TICKET_ID=$(cat $TMPDIR/claim.txt | grep '^1>' | awk '{print $2}')

  # Create work dir
  WORKDIR=$TMPDIR/dss_work/ticket_${TICKET_ID}
  mkdir -p $WORKDIR

  # Download the ticket
  itksnap-wt -dssp-tickets-download $TICKET_ID $WORKDIR > $TMPDIR/download.txt

  # If return code is non-zero we mark the ticket as failed
  if [[ $? -ne 0 ]]; then
    itksnap-wt -dssp-tickets-fail $TICKET_ID "Failed to download ticket"
    continue
  fi

  # Inform the user
  itksnap-wt -dssp-tickets-log $TICKET_ID info "Ticket successfully downloaded"
  itksnap-wt -dssp-tickets-set-progress $TICKET_ID 0 1 0.2

  # Find the workspace file in the download
  INPUT_WSP=$(cat $TMPDIR/download.txt | grep '^1>.*itksnap$' | sed -e "s/^1> //")

  # Get the necessary layers
  SOURCE_IMG=$(itksnap-wt -P -i $INPUT_WSP -llf Source)

  # Inform the user
  itksnap-wt -dssp-tickets-log $TICKET_ID info "Calling segmentation"

  TARGET_SEG=$WORKDIR/wynik.nii.gz
  MODEL=/przykladowy/path/do/modelu
  SEGMENTATOR=~/Pulpit/Studia/Magisterka/Example_Segmentation/Segmentation.py
  #PARAMS=""
  #-p $PARAMS
  python3 $SEGMENTATOR --model $MODEL --input $SOURCE_IMG --output $TARGET_SEG

  # Check that segmentation succeeded
  if [[ ! -f $TARGET_SEG ]]; then
    itksnap-wt -dssp-tickets-fail $TICKET_ID "Segmentation failed"
    continue
  fi
  
  # Inform the user
  itksnap-wt -dssp-tickets-log $TICKET_ID info "Segmentation done"
  itksnap-wt -dssp-tickets-set-progress $TICKET_ID 0 1 0.8
  itksnap-wt -dssp-tickets-log $TICKET_ID info "Packaging up and uploading the workspace"  

  # Package up the workspace
  RESULT_WSP=$WORKDIR/result.itksnap
  itksnap-wt -i $INPUT_WSP \
    -layers-add-seg $TARGET_SEG -props-set-nickname "Segmented" \
    -layers-list -o $RESULT_WSP
    

  # Upload the workspace
  itksnap-wt -i $RESULT_WSP -dssp-tickets-upload $TICKET_ID

  # If return code is non-zero we mark the ticket as failed
  if [[ $? -ne 0 ]]; then
    itksnap-wt -dssp-tickets-fail $TICKET_ID "Failed to upload ticket"
    continue
  fi

  # Set progress and mark ticket as success
  itksnap-wt -dssp-tickets-log $TICKET_ID info "Result uploaded"
  itksnap-wt -dssp-tickets-set-progress $TICKET_ID 0 1 1 
  itksnap-wt -dssp-tickets-success $TICKET_ID

done
