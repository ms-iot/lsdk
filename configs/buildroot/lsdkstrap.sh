
if [ "`id -u`" -eq 0 ]; then
        export PS1="[\u@\h \W]\# "
else
        export PS1="[\u@\h \W]\$ "
fi
