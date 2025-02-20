#!/usr/bin/env bash

trash() {

    : "Wrapper for trash-cli to allow per-directory rules

    The trash command from trash-cli sometimes fails, e.g. in ~/ChromeOS_Files/,
    which is part of a different filesystem from ~/.local/share/Trash/. In mount-points,
    a Trash directory is normally created at its root, but this can't occur from
    /mnt/chromeos due to permissions restrictions.

    This wrapper functions provides a solution for such cases: a rule can be defined to
    use a custom Trash dir within the tree of the mount point.

    The rules should be written one per line in ~/.config/trash/dir_rules, and have the
    form:

        dir-pattern :: trash-dir

    Where 'dir-pattern' is a glob pattern to match the full path of the directory tree
    where the rule applies, and 'trash-dir' is full path of the Trash directory to use.
    The pattern and the Trash path are seperated by ' :: ', i.e. a space, 2 colons, and
    another space.
    "

    local _pwd _tr_cmd _v=2

    # canonical CWD
    _pwd=$( pwd -P ) \
        || return

    # path to trash command on disk
    _tr_cmd=$( type -P trash ) \
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
    # the script was executed, so call the function
    trash "$@"
fi
