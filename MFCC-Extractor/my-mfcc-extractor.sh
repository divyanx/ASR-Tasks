#!/usr/bin/env bash
#This script is meant to work with KALDI-ASR.
#The script can be used with other scripts present in egs/mini_librispeech/s5.
#The scripts when called with an audio file as argument extracts the MFCC features from it.
. ./cmd.sh
. ./path.sh

audio=$1
touch MyData/wav.scp
touch MyData/spk2utt
audiofilename=$(basename $audio)
audioindex=$(echo $audiofilename | sed 's/\./\ /g')
echo "lbi-$audioindex -c -d -s ./$audio |" > MyData/wav.scp
utterance=$(echo "$audiofilename" | cut -f 1 -d '.')
echo "$utterance lbi-$utterance" > MyData/spk2utt
echo "lbi-$utterance $utterance" > MyData/utt2spk
steps/make_mfcc.sh --cmd "$train_cmd" --nj 1 MyData My_make_mfcc My_mfccdir
echo "---------------------------------------------------------------------------------------------"
echo "MFCC features has been created in My_mfccdir in the folder containing this script"
echo "Logs are in My_make_mfcc"
