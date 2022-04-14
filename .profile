export PATH=/run/media/external_10T/Texlive2018/bin/x86_64-linux:$PATH
export MANPATH=/run/media/external_10T/Texlive2018/texmf-dist/doc/man:$PATH
export INFOPATH=run/media/external_10T/Texlive2018/texmf-dist/doc/info:$PATH
export PAGER=most


function sharif_login
{
curl -d "username=username&password=password" -X POST "https://net2.sharif.edu/login"
}


alias 1="sharif_login && exit"
alias 2="sharif_login2 && exit"
alias ۱="1"
alias ۲="2"

function convert_to_all_formats
{
jupyter nbconvert $1 --to html
jupyter nbconvert $1 --to pdf
jupyter nbconvert $1 --to markdown
jupyter nbconvert $1 --to python
}

