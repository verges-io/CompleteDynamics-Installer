#!/bin/bash

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
        echo "ERROR: Not running as root. Execute this script with sudo."
        exit 2
fi

if [[ -z "${1}" ]]; then
        echo "You need to provide a URL to the compressed TAR file (*.tgz) of latest release of Complete Dynamics for Linux."
        echo "https://www.completedynamics.com"
        echo "
USAGE: sudo ./CompleteDynamics.sh https://downloads.completedynamics.com/CompleteDynamics..."
        exit 2
fi

readonly argument="${1}"
readonly iconFile="/usr/share/icons/completedynamics-logo.png"
readonly remoteIconFileLocation="https://verges.io/completedynamics-logo.png"
readonly tmpFileName=$(mktemp)
readonly vanillaDesktopFileContent="#!/usr/bin/xdg-open

[Desktop Entry]
Encoding=UTF-8
Version=1.0
Type=Application
Terminal=false
Exec=/opt/CompleteDynamics/CompleteDynamics
Name=Complete Dynamics
Icon=${iconFile}
"

function finish {
    rm ${tmpFileName}

}
trap finish EXIT

function ensureIcon() {
        if [[ ! -f ${iconFile} ]]; then
                curl -s -o ${iconFile} ${remoteIconFileLocation}
        fi
}

function ensureDesktopIcon() {
        local home="/home/"${SUDO_USER}
        local desktopFolder=${home}"/Desktop"
        if [[ -d ${home}"/Schreibtisch" ]]; then
                desktopFolder=${home}"/Schreibtisch"
        fi

        desktopFileName=${desktopFolder}"/CompleteDynamics.desktop" 

        if [[ ! -f ${desktopFileName} ]]; then
                echo "${vanillaDesktopFileContent}" > ${desktopFileName}
                chown ${SUDO_USER}. ${desktopFileName}
                chmod 0755 ${desktopFileName}
        fi
}

function completeDynamics() {
        local completeDynamicsParentPath=/opt/CompleteDynamics
        if [[ ! -d ${completeDynamicsParentPath} ]]; then
                mkdir ${completeDynamicsParentPath}
        fi

        echo "Downloading the file..."
        curl --progress-bar -o ${tmpFileName} ${argument}
        cd /tmp

        dirName=`tar -tzf ${tmpFileName} | head -1 | cut -f1 -d"/"`

        if [[ -d ${completeDynamicsParentPath}/${dirName} ]]; then
                echo "Latest version '${dirName}' already deployed"
                exit 0
        fi

        tar -xvzf ${tmpFileName} -C ${completeDynamicsParentPath}
        ln -s ${completeDynamicsParentPath}"/"${dirName}"/CompleteDynamics" /opt/CompleteDynamics/CompleteDynamics
}

function main() {
        ensureIcon
        completeDynamics
        ensureDesktopIcon
}

main
