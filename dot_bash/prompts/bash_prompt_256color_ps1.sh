#!/usr/bin/env bash
#
# Prompt setup for bash.
# Base on the following code written by Mike Asberg:
#
#   https://github.com/mkasberg/dotfiles/blob/99c51be200ad7b81a7a5c26ccf947259ad8a29d8/executable_dot_mkps1.sh
#
# Git function based on @necolas’s prompt: https://github.com/necolas/dotfiles
# See the post at https://unix.stackexchange.com/a/521120 for a table of colors.
#
# Different functions generate different parts (segments) of the PS1 prompt.
# Each function should leave the colors in a clean state (e.g. call reset if
# they changed any colors).

# Style commands
Bold="$(tput bold)"
Reset='\[$(tput sgr0)\]'

__mkps1_inject_exitcode() {
    local code=$1;
    if [ "${code}" -ne "0" ]; then echo " ${code} "; fi
}

__mkps1_inject_condaenv() {
    if [[ "${CONDA_DEFAULT_ENV}" ]]; then echo " (e) ${CONDA_DEFAULT_ENV} "; fi
}

__mkps1_inject_git() {
	local s='';
	local branch='';

	# Check if the current directory is in a Git repository.
	git rev-parse --is-inside-work-tree &>/dev/null || return;

	# Check for what branch we’re on.
	# Get the short symbolic ref. If HEAD isn’t a symbolic ref, get a
	# tracking remote branch or tag. Otherwise, get the
	# short SHA for the latest commit, or give up.
	branch="$(git symbolic-ref --quiet --short HEAD 2> /dev/null || \
            git describe --all --exact-match HEAD 2> /dev/null || \
            git rev-parse --short HEAD 2> /dev/null || \
            echo '(unknown)')";

	# Early exit for Chromium & Blink repo, as the dirty check takes too long.
	# Thanks, @paulirish!
	# https://github.com/paulirish/dotfiles/blob/dd33151f/.bash_prompt#L110-L123
	repoUrl="$(git config --get remote.origin.url)";
	if grep -q 'chromium/src.git' <<< "${repoUrl}"; then
		s+='*';
	else
		# Check for uncommitted changes in the index.
		if ! $(git diff --quiet --ignore-submodules --cached); then
			s+='+';
		fi;
		# Check for unstaged changes.
		if ! $(git diff-files --quiet --ignore-submodules --); then
			s+='!';
		fi;
		# Check for untracked files.
		if [ -n "$(git ls-files --others --exclude-standard)" ]; then
			s+='?';
		fi;
		# Check for stashed files.
		if $(git rev-parse --verify refs/stash &>/dev/null); then
			s+='$';
		fi;
	fi;

	[ -n "${s}" ] && s=" [${s}]";

	echo -e " ${1}${branch}${2}${s} ";
}

__mkps1_field() {
    # Inspired in https://riptutorial.com/bash/example/19531/a-function-that-accepts-named-parameters
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -s|--symbol)  # Get symbol to be printed out
                local symbol=$2
                ;;
            -b|--bg)  # Get background color
                if [[ "$2" = "none" ]]; then
                    local BG=""
                else
                    local BG="$(tput setab $2)"
                fi
                ;;
            -f|--fg)  # Get foreground color
                if [[ "$2" = "none" ]]; then
                    local FG=""
                else
                    local FG="$(tput setaf $2)"
                fi
                ;;
            --fg2)  # Get second foreground color
                if [[ "$2" = "none" ]]; then
                    local FG2=""
                else
                    local FG2="$(tput setaf $2)"
                fi
                ;;
            -o|--bold) local isbold=$2;;  # Get bold's true/false value
        esac
        shift
    done
    if $isbold; then local bold="${Bold}"; else local bold=""; fi
    local conf="\[${BG}${FG}${bold}\]";  # Set config

    # We need to run a function at runtime to evaluate the exitcode.
    if [[ "$symbol" = "exitcode" ]]; then  # Last command status code
        echo "${conf}\$(__mkps1_inject_exitcode \$?)${Reset}";
    elif [[ "$symbol" = "conda" ]]; then  # Conda environment
        echo "${conf}\$(__mkps1_inject_condaenv)${Reset}";
    elif [[ "$symbol" = "git" ]]; then  # Git repository details
        echo "${conf}\$(__mkps1_inject_git '${FG}' '${FG2}')${Reset}";
    else
        echo "${conf}${symbol}${Reset}";
    fi
}

__mkps1() {
    local theme_name=$1
    local prompt_symbol=$2
    . ~/.bash/prompts/bash_prompt_256color_themes
    __set_ps1_theme ${theme_name}
    local ps1="\n";
    ps1+="$(__mkps1_field -s exitcode -b ${ExitCode_BG} -f ${ExitCode_FG} -o ${ExitCode_Bold})";
    ps1+="$(__mkps1_field -s ' \h ' -b ${HostName_BG} -f ${HostName_FG} -o ${HostName_Bold})";
    ps1+="$(__mkps1_field -s ' \u ' -b ${UserName_BG} -f ${UserName_FG} -o ${UserName_Bold})";
    ps1+="$(__mkps1_field -s conda -b ${CondaEnv_BG} -f ${CondaEnv_FG} -o ${CondaEnv_Bold})";
    ps1+="$(__mkps1_field -s ' \t ' -b ${Time_BG} -f ${Time_FG} -o ${Time_Bold})";
    ps1+="$(__mkps1_field -s git -b ${Git_BG} -f ${Git_FG} --fg2 ${Git_FG2} -o ${Git_Bold})";
    ps1+="$(__mkps1_field -s ' \w ' -b ${WorkDir_BG} -f ${WorkDir_FG} -o ${WorkDir_Bold})";
    [ -n "$3" -a "$3" = "twolines" ] && ps1+="\n";  # Breakline before prompt
    ps1+=$(__mkps1_field -s "${prompt_symbol} " -b ${UserPrompt_BG} -f ${UserPrompt_FG} -o ${UserPrompt_Bold});
    echo "${ps1}";
}

# To test, for example, print output before changes and after changes
# and see if the diff is correct.
# Uncomment for testing:
#__mkps1;
