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

function printfLineStart() {
    local length="${#1}"
    printf "%s" "${1}" >&2 
    return ${length}
}

function printfAlignRight() {
    local width=$(/usr/bin/tput cols)
    local calcLength=$((${width}-${2}))
    printf "%*s\n" ${calcLength} "${1}"
}

function setLink() {
    local from="${1}"
    local linkPath="${2}"
    local lineStartLen=0

    if [[ -L "${linkPath}" ]]; then 
            
        # Checking whether the link target fits
        local actualLinkTarget="$(readlink ${linkPath})"
        if [[ "${actualLinkTarget}" != "${from}" ]]; then
            printfLineStart "wrong link target from '${linkPath}' to '${actualLinkTarget}'"
            lineStartLen=$?
            rm "${linkPath}"
            ln -s "${from}" "${linkPath}"
            printfAlignRight "fixed" ${lineStartLen}
        else
            printf ${linkPath}
            printfAlignRight "ok" ${lineStartLen}
        fi

    else
        printf "Creating missing link to '${from}'"
        ln -s "${from}" "${linkPath}"
    fi
    echo ""
}

function ensureIcon() {
    local lineStartLen=0
    printfLineStart "Checking for the local Complete Dynamics icon"
    local lineStartLen=$?

    if [[ ! -f ${iconFile} ]]; then
        curl -s -o ${iconFile} ${remoteIconFileLocation}
        printfAlignRight "downloaded" ${lineStartLen}
        return
    fi
    printfAlignRight "found" ${lineStartLen}
}

function ensureDesktopIcon() {
        printfLineStart "Check whether the desktop icon is in place"
        local lineStartLen=$?
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

                printfAlignRight "not found, created" ${lineStartLen}
                return
        fi

        printfAlignRight "found" ${lineStartLen}
}

function completeDynamics() {
        local completeDynamicsParentPath=/opt/CompleteDynamics
        if [[ ! -d ${completeDynamicsParentPath} ]]; then
                mkdir ${completeDynamicsParentPath}
        fi

        echo "Downloading the tar file..."
        curl --progress-bar -o ${tmpFileName} ${argument}

        dirName=`tar -tzf ${tmpFileName} | head -1 | cut -f1 -d"/"`

        if [[ -d ${completeDynamicsParentPath}/${dirName} ]]; then
                echo "Latest version '${dirName}' already deployed"
                exit 0
        fi

        printfLineStart "Unpacking the tar file..."
        local lineStartLen=$?
        tar -xzf ${tmpFileName} -C ${completeDynamicsParentPath}
        printfAlignRight "done" ${lineStartLen}

        setLink ${completeDynamicsParentPath}"/"${dirName}"/CompleteDynamics" /opt/CompleteDynamics/CompleteDynamics
}

function main() {
        echo "
CompleteDynamics Installer v0.1
-------------------------------
"
        ensureIcon
        completeDynamics
        ensureDesktopIcon
}

main
