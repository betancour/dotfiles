#!/usr/bin/env bash

LOG="${HOME}/opt/logs/dotfiles.log"
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
	_process "→ Creating directory at ${DIR} and setting permissions"
	mkdir -p "${DIR}"

	_process "→ Creating directory at ${LOG} and setting permissions" 
	mkdir -p "${LOG}"

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

        source "${HOME}/.bash_profile"
        [[ $? ]] && _success "All files have been copied"
    fi
}

setup_git_authorship() {
	GIT_AUTHOR_NAME="$(git config user.name)"
	GIT_AUTHOR_EMAIL="$(git config user.email)"

  if [[ ! -z "$GIT_AUTHOR_NAME" ]]; then
    _process "→ Setting up Git author"

    read USER_GIT_AUTHOR_NAME
    if [[ ! -z "$USER_GIT_AUTHOR_NAME" ]]; then
      GIT_AUTHOR_NAME="${USER_GIT_AUTHOR_NAME}"
      $(git config --global user.name "$GIT_AUTHOR_NAME")
    else
      _warning "No Git user name has been set.  Please update manually"
    fi

    read USER_GIT_AUTHOR_EMAIL
    if [[ ! -z "$USER_GIT_AUTHOR_EMAIL" ]]; then
      GIT_AUTHOR_EMAIL="${USER_GIT_AUTHOR_EMAIL}"
      $(git config --global user.email "$GIT_AUTHOR_EMAIL")
    else
      _warning "No Git user email has been set.  Please update manually"
    fi
  else
    _process "→ Git author already set, moving on..."
  fi
}

install() {
 download_dotfiles
 link_dotfiles
 setup_git_authorship
}

install
