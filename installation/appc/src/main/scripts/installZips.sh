#!/bin/bash

###
# ============LICENSE_START=======================================================
# APPC
# ================================================================================
# Copyright (C) 2017-2019 AT&T Intellectual Property. All rights reserved.
# ================================================================================
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ============LICENSE_END=========================================================
###

if [ -z "$SETTINGS_FILE" -a -z "$GLOBAL_SETTINGS_FILE" -a -s "$HOME"/.m2/settings.xml ]
then
  DEFAULT_MAVEN_SETTINGS=${HOME}/.m2/settings.xml
  SETTINGS_FILE=${SETTINGS_FILE:-${DEFAULT_MAVEN_SETTINGS}}
  GLOBAL_SETTINGS_FILE=${GLOBAL_SETTINGS_FILE:-${DEFAULT_MAVEN_SETTINGS}}
fi

APPC_HOME=${APPC_HOME:-/opt/onap/appc}
SDNC_HOME=${SDNC_HOME:-/opt/onap/sdnc}

targetDir=${1:-${APPC_HOME}}
sdnc_targetDir=${1:-${SDNC_HOME}}

#The featureDir holds the install-feature shell scripts for each feature
featureDir=$2/featureDir

#The repoDir is where the classes are extracted to. This will be merged with the opendaylight
#  system directory.
repoDir=$2/repoDir


APPC_FEATURES=" \
 appc-core \
 appc-sdc-listener \
 appc-lifecycle-management \
 appc-provider \
 appc-event-listener \
 appc-dispatcher \
 appc-chef-adapter \
 appc-netconf-adapter \
 appc-rest-adapter \
 appc-dmaap-adapter \
 appc-dg-util \
 appc-metric \
 appc-dg-shared \
 appc-iaas-adapter \
 appc-ansible-adapter \
 appc-oam \
 appc-sequence-generator \
 appc-config-generator \
 appc-config-data-services \
 appc-artifact-handler \
 appc-config-adaptor \
 appc-config-audit \
 appc-config-encryption-tool \
 appc-config-flow-controller \
 appc-config-params \
 appc-aai-client \
 appc-network-inventory-client \
 appc-design-services \
 appc-interfaces-service"


APPC_VERSION=${APPC_VERSION:-0.0.1}
APPC_CDT_VERSION=${APPC_CDT_VERSION:-0.0.1}
APPC_OAM_VERSION=${APPC_OAM_VERSION:-0.1.1}
AAF_SHIRO_VERSION=${AAF_SHIRO_VERSION:-2.1.7-SNAPSHOT}

tmpDir=/tmp/appc-${APPC_VERSION}

if [ ! -d ${targetDir} ]
then
  mkdir -p ${targetDir}
fi

if [ ! -d ${tmpDir} ]
then
  mkdir -p ${tmpDir}
fi

cwd=$(pwd)

mavenOpts="-s ${SETTINGS_FILE} -gs ${GLOBAL_SETTINGS_FILE}"
cd ${tmpDir}

echo "Installing APP-C version ${APPC_VERSION}"
for feature in ${APPC_FEATURES}
do
  rm -f ${tmpDir}/${feature}-installer*.zip
  mvn -U ${mavenOpts} org.apache.maven.plugins:maven-dependency-plugin:2.9:copy -Dartifact=org.onap.appc:${feature}-installer:${APPC_VERSION}:zip -DoutputDirectory=${tmpDir} -Dmaven.wagon.http.ssl.allowall=true -Dmaven.wagon.ssl.insecure=true
  unzip -d ${featureDir} ${tmpDir}/${feature}-installer*zip
  unzip -n -d ${repoDir} ${featureDir}/${feature}/${feature}*zip
  rm -f ${featureDir}/${feature}/${feature}*zip
done

echo "Installing platform-logic for APP-C"
rm -f ${tmpDir}/platform-logic-installer*.zip
mvn -U ${mavenOpts} org.apache.maven.plugins:maven-dependency-plugin:2.9:copy -Dartifact=org.onap.appc.deployment:platform-logic-installer:${APPC_OAM_VERSION}:zip -DoutputDirectory=${tmpDir} -Dmaven.wagon.http.ssl.allowall=true -Dmaven.wagon.ssl.insecure=true
unzip -d ${targetDir} ${tmpDir}/platform-logic-installer*.zip

echo "Downloading dg-loader DGs from nexus"
mvn -U ${mavenOpts} org.apache.maven.plugins:maven-dependency-plugin:2.9:copy -Dartifact=org.onap.appc:appc-dg-provider:${APPC_VERSION} -DoutputDirectory=${tmpDir}
unzip -d ${targetDir}/svclogic/graphs/appc/json ${tmpDir}/appc-dg-provider*.jar json/**
mv ${targetDir}/svclogic/graphs/appc/json/json ${targetDir}/svclogic/graphs/appc/json/dg-loader-dgs

echo "Downloading dg-loader-provider jar from nexus"
mvn -U ${mavenOpts} org.apache.maven.plugins:maven-dependency-plugin:2.9:copy -Dartifact=org.onap.appc.plugins:dg-loader-provider:${APPC_VERSION}:jar:jar-with-dependencies -DoutputDirectory=${targetDir}/data
mv ${targetDir}/data/dg-loader-provider-*-jar-with-dependencies.jar ${targetDir}/data/dg-loader-provider-jar-with-dependencies.jar

echo "Downloading aaf-cadi-shiro from nexus"
mvn -U ${mavenOpts} org.apache.maven.plugins:maven-dependency-plugin:2.9:copy -Dartifact=org.onap.aaf.cadi:aaf-shiro-aafrealm-osgi-bundle:${AAF_SHIRO_VERSION} -DoutputDirectory=${targetDir}/data
mv ${targetDir}/data/aaf-shiro-aafrealm-osgi-bundle-*.jar ${targetDir}/data/aaf-shiro-aafrealm-osgi-bundle.jar

echo "Setting keyfile to readonly"
chmod 400 ${targetDir}/data/stores/org.onap.appc.keyfile

echo "Downloading CDT Proxy Jar from nexus"
mvn -U ${mavenOpts} org.apache.maven.plugins:maven-dependency-plugin:2.9:copy -Dartifact=org.onap.appc.cdt:cdt-proxy-service:${APPC_CDT_VERSION} -DoutputDirectory=${targetDir}/cdt-proxy-service
mv ${targetDir}/cdt-proxy-service/cdt-proxy-service-*.jar ${targetDir}/cdt-proxy-service/cdt-proxy-service.jar

find ${targetDir} -name '*.sh' -exec chmod +x '{}' \;

cd $cwd

