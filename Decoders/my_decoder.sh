#!/usr/bin/env bash
#This script is meant to work with KALDI-ASR.
#The script can be used with other scripts present in egs/mini_librispeech/s5.
#The scripts when called with an audio file as argument extracts the MFCC features from it.
. ./cmd.sh
. ./path.sh
mkdir -p data/convert_me
mdata=./data/convert_me
audio=$1
touch $mdata/wav.scp
touch $mdata/spk2utt
audiofilename=$(basename $audio)
audioindex=$(echo $audiofilename | sed 's/\./\ /g')
echo "lbi-$audioindex -c -d -s ./$audio |" > $mdata/wav.scp
utterance=$(echo "$audiofilename" | cut -f 1 -d '.')
echo "$utterance lbi-$utterance" > $mdata/spk2utt
echo "lbi-$utterance $utterance" > $mdata/utt2spk


cp -r 0013_librispeech_v1_lm/data/lang_test* data/ 
cp -r 0013_librispeech_v1_chain/exp . # Copy chain model and i-vector extractor.
cp -r 0013_librispeech_v1_extractor/exp . 
export train_cmd="run.pl"
export decode_cmd="run.pl --mem 2G"

utils/copy_data_dir.sh data/convert_me data/convert_me_hires

steps/make_mfcc.sh \
    --nj 1 \
    --mfcc-config conf/mfcc_hires.conf \
    --cmd "$train_cmd" data/convert_me_hires
steps/compute_cmvn_stats.sh data/convert_me_hires
utils/fix_data_dir.sh data/convert_me_hires

nspk=$(wc -l <data/convert_me_hires/spk2utt)
steps/online/nnet2/extract_ivectors_online.sh  \
    --cmd "$train_cmd" --nj "${nspk}" \
    data/convert_me_hires exp/nnet3_cleaned/extractor \
    exp/nnet3_cleaned/ivectors_convert_me_hires

export dir=exp/chain_cleaned/tdnn_1d_sp
export graph_dir=$dir/graph_tgsmall
utils/mkgraph.sh --self-loop-scale 1.0 --remove-oov \
    data/lang_test_tgsmall $dir $graph_dir


steps/nnet3/decode.sh --acwt 1.0 --post-decode-acwt 10.0 \
    --nj 1 --cmd "$decode_cmd" \
    --online-ivector-dir exp/nnet3_cleaned/ivectors_convert_me_hires \
    $graph_dir data/convert_me_hires $dir/decode_convert_me_tgsmall

steps/lmrescore_const_arpa.sh --cmd "$decode_cmd" data/lang_test_{tgsmall,tglarge} \
    data/convert_me_hires $dir/decode_convert_me_{tgsmall,tglarge}

steps/get_ctm.sh data/convert_me exp/chain_cleaned/tdnn_1d_sp/graph_tgsmall \
    exp/chain_cleaned/tdnn_1d_sp/decode_convert_me_tglarge
