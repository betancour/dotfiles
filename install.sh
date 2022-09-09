#!/usr/bin/zsh

LOG="${HOME}/opt/dotfiles.log"
GITHUB_USER="betancour"
GITHUB_REPO="dotfiles"
USER_GIT_AUTHOR_NAME="Yitzhak B. Solorzano"
USER_GIT_AUTHOR_EMAIL="betancour@gmail.com"
DIR="${HOME}/opt/${GITHUB_REPO}"

_process() {
    echo "$(date) PROCESSING: $@" >> $LOG
    printf "$(tput setaf 6) %s...$(tput sgr0)\n" "$@"
}

_success() {
    local message=$1
    printf "%s✓ Success:%s\n" "$(tput setaf 2)" "$(tput sgr0) $message"
}

download_dotfiles() {
    _process "→ Creating' directory at ${DIR} and setting permissions"
    mkdir -p "${DIR}"	

    _process "→ Downloading repository to /tmp directory"
    curl  -#fLo /tmp/${GITHUB_REPO}.tar.gz "https://github.com/${GITHUB_USER}/${GITHUB_REPO}/tarball/main"

    _process "→ Extracting files to ${DIR}"
    tar -zxf /tmp/${GITHUB_REPO}.tar.gz --strip-components 1 -C "${DIR}"

    _process "→ Removing tarball from /tmp directory"
    rm -rf /tmp/${GITHUB_REPO}.tar.gz

    [[ $? ]] && _success "${DIR} created, repository downloaded and extracted"

    cd "${DIR}"
}

link_dotfiles() {
    if [[ -f "${DIR}/opt/files" ]]; then
        _process "→ Symlinking dotfiles in /configs"

        files="${DIR}/opt/files"
        OIFS=$IFS
        IFS=$'\r\n'
        links=($(cat "${files}"))

        for index in ${!links[*]}
        do
            for link in ${links[$index]}
            do
                _process "→ Linking ${links[$index]}"
                IFS=$' '
                file=(${links[$index]})
                ln -fs "${DIR}/${file[0]}" "${HOME}/${file[1]}"
            done
            IFS=$'\r\n'
        done

        IFS=$OIFS

        source "${HOME}/.profile"
        [[ $? ]] && _success "All files have been copied"
    fi
}
install() {
 download_dotfiles
 link_dotfiles
}

install
