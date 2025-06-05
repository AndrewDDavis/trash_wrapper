#!/bin/env bash

# dependencies
_deps=( docsh err_msg run_vrb )

trash-wrapper() {

    : """Wrapper for trash-cli that enables per-directory rules

    Usage: trash-wrapper [options] {file} ...

    The \`trash\` command from trash-cli sometimes fails, e.g. in /mnt/chromeos/MyFiles/,
    which is part of a different filesystem from ~/.local/share/Trash/. In mount-points,
    a Trash directory is normally created at the root, but this can't occur within
    /mnt/chromeos due to permissions restrictions of the container.

    This command provides a solution for such cases: rules can be defined to ensure
    that a particular Trash directory is used, ideally one within the tree of the mount
    point.

    All options and positional arguments are passed to the 'trash' command. Refer to
    its manpage for usage details.

    The rules should be written one per line in ~/.config/trash/dir_rules, and have the
    form:

        dir-pattern :: trash-dir

      - 'dir-pattern' is a glob pattern to match the physical path of the directory
        tree in which the rule applies. This function resolves any symlinks in the path
        before matching the pattern by using \`pwd -P\`.

      - 'trash-dir' is the full path of the Trash directory to use.

      - The pattern and the Trash path are seperated by ' :: ', i.e. a space, 2 colons,
        and another space.

      - No quoting or other characters should be included, unless they are part of the
        pattern.

    For the above example, the ~/.config/trash/dir_rules file contains the line:
    /mnt/chromeos/MyFiles* :: /mnt/chromeos/MyFiles/.Trash
    """

    [[ -$# -eq 0  || $1 == @(-h|--help) ]] &&
        { docsh -TD || return 2; return; }

    # var defaults
    local _v=2 \
        cwd tr_cmd \
        rules_fn="$HOME"/.config/trash/dir_rules

    # physical CWD
    cwd=$( pwd -P ) \
        || return

    # path to trash command on disk
    tr_cmd=( "$( builtin type -P trash )" ) \
        || return 9

    # import dir rules, if present
    if [[ -s $rules_fn  && -r $rules_fn ]]
    then
        local rl rlines \
            pat tdir

        mapfile -t rlines < "$rules_fn"

        for rl in "${rlines[@]}"
        do
            pat=${rl% :: *}
            tdir=${rl##* :: }

            # shellcheck disable=SC2053
            [[ $cwd == $pat ]] && {

                tr_cmd+=( --trash-dir="$tdir" )
                break
            }
        done
    else
        (( _v > 1 )) &&
            err_msg w "no rules read from '$rules_fn'"
    fi

    # run trash, possibly verbosely
    run_vrb -v "${_v}" "${tr_cmd[@]}" "$@"
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]
then
    # script was executed, rather than sourced

    # import dependencies
    [[ -v BASH_FUNCLIB ]] \
        || BASH_FUNCLIB="$HOME"/.bash_lib

    source "$BASH_FUNCLIB"/import_func.sh \
        || exit 9

    import_func "${_deps[@]}" \
        || exit

    trash-wrapper "$@" \
        || exit

else
    # sourced script should have import_func in the environment

    import_func "${_deps[@]}" \
        || return

    unset _deps
fi
