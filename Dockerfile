FROM quay.io/nordicesmhub/cesm_libs:latest

#####EXTRA LABELS#####
LABEL autogen="no" \ 
    software="CESM" \ 
    version="2" \
    software.version="2.1.1" \ 
    about.summary="Community Earth System Model" \ 
    base_image="quay.io/nordicesmhub/cesm_libs" \
    about.home="http://www.cesm.ucar.edu/models/simpler-models/N1850/index.html" \
    about.license="Copyright (c) 2017, University Corporation for Atmospheric Research (UCAR). All rights reserved." 
      
MAINTAINER Anne Fouilloux <annefou@geo.uio.no>

ENV USER=root
ENV HOME=/root

RUN mkdir -p $HOME/.cime \
             $HOME/work \
             $HOME/inputdata \
             $HOME/archive \
             $HOME/cases 

COPY config_files/* $HOME/.cime/

RUN cd $HOME \
    && git clone -b release-cesm2.1.1 https://github.com/ESCOMP/CESM.git \
    && cd CESM \
    && sed -i.bak "s/'checkout'/'checkout', '--trust-server-cert', '--non-interactive'/" ./manage_externals/manic/repository_svn.py \
    && ./manage_externals/checkout_externals

ENV CESM_PES=40
ENV PROJECT=nn1000k

## Case-1: NTASK=$CESM_PES

RUN CASE=case1 && \
    sed -i -e "s/\$CESM_PES/$CESM_PES/g" $HOME/.cime/config_machines.xml \
    && cd $HOME/CESM/cime/scripts \
    && ./create_newcase --case $HOME/cases/F2000climo-f19_g17-$CASE --res f19_g17 \
       --compset F2000climo --mach saga --run-unsupported --project $PROJECT && \
    cd $HOME/cases/F2000climo-f19_g17-$CASE                && \
    NUMNODES=-1                                            && \
    ./xmlchange --file env_mach_pes.xml --id NTASKS --val ${NUMNODES} && \
    ./xmlchange --file env_mach_pes.xml --id NTASKS_ESP --val 1 && \
    ./xmlchange --file env_mach_pes.xml --id ROOTPE --val 0 && \
    ./case.setup && ./case.build
    
WORKDIR $HOME/cases/

COPY run_case $HOME/cases/

CMD ["/bin/bash"]
