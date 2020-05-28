#!/bin/bash

export XILINX_XRT=/opt/xilinx/xrt/
export LD_LIBRARY_PATH=$XILINX_XRT/lib:$LD_LIBRARY_PATH
export PATH=$XILINX_XRT/bin:$PATH
