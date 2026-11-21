function load_env_file --description 'Load bash-style `export K=V` lines from a file'
    test -f $argv[1]; or return 0
    while read -l line
        set -l m (string match -r '^\s*export\s+([A-Za-z_][A-Za-z0-9_]*)=(.*)$' -- $line)
        or continue
        set -l name $m[2]
        set -l val (string trim -c '"\'' -- $m[3])
        # expand $VAR / ${VAR} references (PATH joined with ':')
        for ref in (string match -rag '\$\{?([A-Za-z_][A-Za-z0-9_]*)\}?' -- $val)
            set -l rep ''
            if test $ref = PATH
                set rep (string join : $PATH)
            else if set -q $ref
                set rep (string join : $$ref)
            end
            set val (string replace -a -- '${'$ref'}' $rep $val)
            set val (string replace -a -- '$'$ref $rep $val)
        end
        if test $name = PATH
            set -gx PATH (string split : -- $val)
        else
            set -gx $name $val
        end
    end <$argv[1]
end
