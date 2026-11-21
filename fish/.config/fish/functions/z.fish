function z --description 'zoxide jump; no args = interactive'
    if test (count $argv) -eq 0
        __zoxide_zi
    else
        __zoxide_z $argv
    end
end
