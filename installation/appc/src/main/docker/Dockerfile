# ============LICENSE_START==========================================
# ONAP : APPC
# ===================================================================
# Copyright (C) 2017-2019 AT&T Intellectual Property. All rights reserved.
# ===================================================================
#
# Unless otherwise specified, all software contained herein is licensed
# under the Apache License, Version 2.0 (the License);
# you may not use this software except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# ECOMP is a trademark and service mark of AT&T Intellectual Property.
# ============LICENSE_END============================================

# Base ubuntu with added packages needed for ONAP
FROM onap/ccsdk-odlsli-alpine-image:0.7.0
MAINTAINER APP-C Team (appc@lists.openecomp.org)

# run as root to install ps to comply with karaf scripts
USER root
RUN apk add --no-cache procps
RUN apk add --no-cache openssh
RUN apk add --no-cache sshpass

# Set the Env. Variable in the container to add the APPC CONFIG DIR (the SDNC_CONFIG_DIR is inherited from SDNC Image)
ENV APPC_CONFIG_DIR /opt/onap/appc/data/properties

# Copy the opt folder to the container's /opt folder
COPY --chown=odl:odl opt /opt

#Copy the directory containing each features' install script
COPY --chown=odl:odl featureDir /opt/onap/appc/features

#Copy the directory containing a system folder and an etc folder in order
#  to merge both of these with the opendaylight folders of the same names.
COPY --chown=odl:odl repoDir /opt/opendaylight
RUN chown -R odl:odl /opt

USER odl
RUN ln -s /opt/onap/appc /opt/appc

# cvass dir stores VNF's configure via Audit or Sync LCM
RUN mkdir /opt/onap/appc/cvaas

#Start opendaylight and pre-install the appc features
#RUN opt/onap/appc/bin/dockerInstall.sh

# Expose port 8181 for ODL REST calls
EXPOSE 8181
