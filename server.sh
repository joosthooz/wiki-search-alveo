#!/bin/bash

source xilinx-xrt.sh
cd server || exit -1

# scl enable devtoolset-7 bash
source /opt/rh/devtoolset-7/enable
#source /opt/applics/bin/xilinx-vitis-2019.2.sh
source /opt/apps/xilinx/Vitis/2019.2/settings64.sh
export XILINX_XRT=/opt/xilinx/xrt/
export LD_LIBRARY_PATH=$XILINX_XRT/lib:/usr/lib64/clang-private:`pwd`/../alveo:$LD_LIBRARY_PATH
export PATH=$XILINX_XRT/bin:$PATH

export CARGO_HOME=/work/jvanstraten/rustc/cargo
export RUSTUP_HOME=/work/jvanstraten/rustc/rustup
export PATH="/work/jvanstraten/rustc/cargo/bin:$PATH"
export LC_ALL=C
export LC_CTYPE=
export LANGUAGE=
export LANG=
# export LD_LIBRARY_PATH="/work/shared/wiki-search-alveo/wiki-search-alveo-tta-snappy/vitis-2019.2"

killall server

cargo run --release -- ../../../fletcher-alveo-old/enwiki-no-meta-15-chunks ../alveo/vitis-2019.2/xclbin/word_match
#cargo run --release -- ../../../fletcher-alveo-old/simplewiki ../alveo/vitis-2019.2/xclbin/word_match



