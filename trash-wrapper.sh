#!/usr/bin/env bash

trash-wrapper() {

    : "Wrapper for trash-cli that enables per-directory rules

    The \`trash\` command from trash-cli sometimes fails, e.g. in /mnt/chromeos/MyFiles/,
    which is part of a different filesystem from ~/.local/share/Trash/. In mount-points,
    a Trash directory is normally created at the root, but this can't occur within
    /mnt/chromeos due to permissions restrictions of the container.

    This wrapper command provides a solution for such cases: a rule can be defined to
    use a custom Trash dir within the tree of the mount point.

    The rules should be written one per line in ~/.config/trash/dir_rules, and have the
    form:

        dir-pattern :: trash-dir

      - 'dir-pattern' is a glob pattern to match the canonical path of the directory
        tree in which the rule applies. This function resolves any symlinks in the path
        before matching the pattern by using \`pwd -P\`.

      - 'trash-dir' is the full path of the Trash directory to use.

      - The pattern and the Trash path are seperated by ' :: ', i.e. a space, 2 colons,
        and another space.

    For the above example, the ~/.config/trash/dir_rules file contains the line:
    /mnt/chromeos/MyFiles* :: /mnt/chromeos/MyFiles/.Trash
    "

    [[ -$# -eq 0  || $1 == @(-h|--help) ]] &&
        { docsh -TD || return 2; return; }

    local _pwd _tr_cmd _v=2

    # canonical CWD
    _pwd=$( pwd -P ) \
        || return

    # path to trash command on disk
    _tr_cmd=$( builtin type -P trash ) \
        || return

    # read the dir rules
    local _tr_args=() _rules_fn="$HOME"/.config/trash/dir_rules

    if [[ -s $_rules_fn  && -r $_rules_fn ]]
    then
        local l lines pat tdir
        IFS='' mapfile -t lines < "$_rules_fn"

        for l in "${lines[@]}"
        do
            pat=${l% :: *}
            tdir=${l##* :: }

            # shellcheck disable=SC2053
            [[ $_pwd == $pat ]] && {

                _tr_args+=( --trash-dir="$tdir" )
                break
            }
        done
    else
        err_msg w 'rules file not found'
    fi

    (
        [[ ${_v-} -gt 1 ]] && set -x
        "$_tr_cmd" "${_tr_args[@]}" "$@"
    )
}

if [[ $0 == "${BASH_SOURCE[0]}" ]]
then
    # the script was executed, so import dependencies and call the function
    source ~/.bash_lib/import_func.sh \
        || return 63

    import_func docsh err_msg \
        || return 62

    trash-wrapper "$@"
fi
