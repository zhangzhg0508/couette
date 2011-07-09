#!/bin/sh
#PBS -S /bin/sh
#PBS -j oe -o run.log
#Copyright 2011 Anthony Youd/Newcastle University
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

cd $PBS_O_WORKDIR
uniq $PBS_NODEFILE
if [ $? != 0 ]; then
  exit
fi

#****************************************************************************
#PARAMETERS
#****************************************************************************
SERIAL=0
NPROCS=1
EXE=couette_mod.out
DATA=parameters.f90
DATA_DIR=`pwd`
RUN_DIR=/work/ay_$PBS_JOBID

#****************************************************************************
#NO CHANGES NECESSARY BELOW HERE
#****************************************************************************
mkdir $RUN_DIR
mv $EXE $RUN_DIR
cp $DATA $RUN_DIR
if [ -e $DATA_DIR/end_state.dat ]; then
   mv end_state.dat $RUN_DIR
fi
cd $RUN_DIR
if [ $SERIAL == 1 ]; then
  time ./$EXE
else
  echo No. processors = $NPROCS
  for NODE in `uniq $PBS_NODEFILE`
  do
    if [ `hostname` != $NODE ]; then
      ssh $NODE "mkdir $RUN_DIR"
      scp $EXE $DATA $NODE:$RUN_DIR
    fi
  done
  time mpiexec -l -n $NPROCS $EXE
fi
rm $EXE
bzip2 -9 `find $RUN_DIR/ -type f ! -iname "end_state.dat" \
                                 ! -iname "parameters.f90" \
                                 ! -iname "xsect*.dat"`

NXSECT=`ls | grep "xsect" | wc -l`
if [ $NXSECT -gt 1 ]; then
  tar cvvf xsect.tar xsect*
  bzip2 -9 xsect.tar
  rm xsect*.dat
elif [ $NXSECT == 1 ]; then
  bzip2 -9 xsect*.dat
fi

cp -r $RUN_DIR/* $DATA_DIR
if [ $SERIAL == 0 ]; then
  for NODE in `uniq $PBS_NODEFILE`
  do
    if [ `hostname` != $NODE ]; then
      ssh $NODE "rm -rf $RUN_DIR"
    fi
  done
fi
rm -rf $RUN_DIR
