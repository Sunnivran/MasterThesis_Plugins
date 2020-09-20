#!/bin/bash

INPUT_PATH=$1
OUTPUT_PATH=$2
PARAMS=$3

MODEL=/przykladowy/path/do/modelu
SEGMENTATOR_PATH=~/Pulpit/Studia/Magisterka/Example_Segmentation/Segmentation.py

echo "Redirecting script started"

echo "Extension bash script:"
echo "  model: $MODEL"
echo "  input: $INPUT_PATH"
echo "  output: $OUTPUT_PATH"
echo "  parms: $PARAMS"

#echo "Calling python2.7 $SEGMENTATOR_PATH --model $MODEL --input $INPUT_PATH -p $PARAMS --output $OUTPUT_PATH"
python2.7 $SEGMENTATOR_PATH --model $MODEL --input $INPUT_PATH -p $PARAMS --output $OUTPUT_PATH

echo "Redirecting script completed"
