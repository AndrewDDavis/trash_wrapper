# Trash-Wrapper

Wrapper script for `trash-cli` that enables per-directory rules.

The `trash` command from `trash-cli` sometimes fails, e.g. in `/mnt/chromeos/MyFiles/`,
which is part of a different filesystem from `~/.local/share/Trash/`. In mount-points,
a Trash directory is normally created at the root, but this can't occur within
`/mnt/chromeos/` due to permissions restrictions of the container.

This wrapper command provides a solution for such cases: a rule can be defined to
use a custom Trash dir within the tree of the mount point.

The rules should be written one per line in ~/.config/trash/dir_rules, and have the
form:

    dir-pattern :: trash-dir

Where 'dir-pattern' is a glob pattern to match the full path of the directory tree
where the rule applies, and 'trash-dir' is full path of the Trash directory to use.
The pattern and the Trash path are seperated by ' :: ', i.e. a space, 2 colons, and
another space.

For the above example, the `~/.config/trash/dir_rules` file contains the line:
`/mnt/chromeos/MyFiles* :: /mnt/chromeos/MyFiles/.Trash`
