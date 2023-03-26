
#Get script run directory
function F_getRunDir()
{
    mypath="$(cd "$(dirname "$0")" >/dev/null 2>&1 || exit; pwd -P)"
}


F_getRunDir $@
echo "mypath=[${mypath}]"
