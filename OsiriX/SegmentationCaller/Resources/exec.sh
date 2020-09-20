#!/bin/bash

INPUT_PATH=$1
OUTPUT_PATH=$2
PARAMS=$3

MODEL=/przykladowy/path/do/modelu
SEGMENTATOR_PATH=/Users/kask/Desktop/Magisterka/Example_Segmentation/Segmentation.py

echo "[SSC] Redirecting script started" >> $HOME/Desktop/OsiriX.exec.txt

echo "[SSC] Extension bash script:" >> $HOME/Desktop/OsiriX.exec.txt
echo "[SSC]  model: $MODEL" >> $HOME/Desktop/OsiriX.exec.txt
echo "[SSC]  input: $INPUT_PATH" >> $HOME/Desktop/OsiriX.exec.txt
echo "[SSC]  output: $OUTPUT_PATH" >> $HOME/Desktop/OsiriX.exec.txt
echo "[SSC]  parms: $PARAMS" >> $HOME/Desktop/OsiriX.exec.txt

#echo "Calling python2.7 $SEGMENTATOR_PATH --model $MODEL --input $INPUT_PATH -p $PARAMS --output $OUTPUT_PATH"
python "$SEGMENTATOR_PATH" --model "$MODEL" --input "$INPUT_PATH" --params "$PARAMS" --output "$OUTPUT_PATH" >> $HOME/Desktop/OsiriX.exec.txt

echo "Redirecting script completed" >> $HOME/Desktop/OsiriX.exec.txt
