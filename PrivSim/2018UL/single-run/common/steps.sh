#!/bin/bash

# collecting input arguments:
id=$1
inputpath=$2
scram=$3
cmssw=$4
eosarea=$5
jobname=$6
config=$7
step=$8

# prepare:
set -e
set -o pipefail

# identify simulation step:
declare -a steps=( "LHE" "pLHE" "GEN" "SIM" "DR" "HLT" "RECO" "MINI" )
arraylength=${#steps[@]}
for (( i=0; i<${arraylength}; i++ ))
do
    if [ "$step" = "${steps[i]}" ]
    then
        prestep=${steps[$(( i-1 ))]}
    fi
done

# define input paths:
if [ "$prestep" = "LHE" ]
then
    stagein=${inputpath}/${jobname}/LHE/split
    inputfile=${jobname}_${id}.lhe
    xrdcp -fs ${stagein}/${inputfile}.xz .
    xz -v -d ${inputfile}.xz
else
    stagein=${inputpath}/${jobname}/${prestep}
    inputfile=${jobname}_${id}_${prestep}.root
    xrdcp -fs ${stagein}/${inputfile} .
fi

# define output paths:
stageout=${eosarea}/${jobname}/${step}
if [ ! -d ${stageout} ]
then
    mkdir ${stageout}
fi
output=${jobname}_${id}_${step}.root

# prep config files:
sed -i "s@xinput@$inputfile@g" $config
sed -i "s@xfileout@$output@g" $config

# step cmssw area:
export HOME=/tmp
export EOS_MGM_URL=root://eoscms.cern.ch
source /cvmfs/cms.cern.ch/cmsset_default.sh
export SCRAM_ARCH=$scram
scram project $cmssw
cd ${cmssw}/src/
eval `scramv1 runtime -sh`
scramv1 b -j8
mv ../../${inputfile} .
mv ../../$config .

# run simulation step:
cmsRun $config
xrdcp -fs $output ${stageout}/${output}
cd ../..

# clean area in working machine:
rm -rf CMSSW*
rm -rf $(whoami).cc
