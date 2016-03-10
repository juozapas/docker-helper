
alias dcm='docker-machine'


dcexec() {
    # (for docker-compose containers)
    # because it's tedious having to type
    # `docker exec -it myproject_myservice_1 bash`
    # every time I want a shell into a running container
    if [ "$#" -gt 1 ]; then
        arg="$@"
    else
        arg="bash"
    fi
    docker exec -it "${PWD##*/}_$1_1" $arg
}


dnsmasq-restart(){
    echo "Restarting dnsmasq..."
    sudo launchctl stop homebrew.mxcl.dnsmasq
    sudo launchctl start homebrew.mxcl.dnsmasq
}

docker-machine-env() {
    eval $(docker-machine env $1)
}
alias dme='docker-machine-env'

docker-machine-dns() {
    dmip=$(dcm ip $1)
    dnsconf=/usr/local/etc/dnsmasq.conf
    if [ ! -e /etc/resolver/$1 ]; then
        echo "adding $1 entry to resolvers"
        sudo tee /etc/resolver/$1 >/dev/null <<EOF
nameserver 127.0.0.1
EOF
    fi
    if grep -q /$1/$dmip $dnsconf; then
        echo "correct dnsmasq entry already exists"
    elif grep -q ^address=/$1/ $dnsconf; then
        echo "hostname $1 already present in dnsmasq - updating"
        # remove line if ip already present for different hostname
        sed -i '' -E "\%^address=/[[:alnum:]_.-]+/$dmip%d" $dnsconf
        # update existing hostname with new ip
        sed -i '' -E "s%^(address=/$1)/([[:digit:].]+)$%\1/$dmip%g" $dnsconf
        dnsmasq-restart
    else
        # neither hostname nor ip are present
        echo "adding $1/$dmip entry to dnsmasq"
        echo "address=/$1/$dmip" >> /usr/local/etc/dnsmasq.conf
        dnsmasq-restart
    fi
}

docker-machine-use() {
    docker-machine start $1
    docker-machine-dns $1
    docker-machine-env $1
}

alias dmuse='docker-machine-use'

dcc (){
    if [[ "$(uname)" == "Darwin" ]] && [ -z "$DOCKER_HOST" ]; then
        echo 'docker env was not set, setting to dev!'
        dmuse dev
    fi
    docker-compose $@
}

dcb() {
    dcc build $@
}

dcup() {
    docker-compose up --no-deps -d $1
}

dcrebuild() {
    dcb $1
    dcup $1
}

dclog() {
  dcc logs $@
}

dcdellogs() {
    #delete logs of containers, defained in docker-compose.yml of current dir
    if [[ $1 == "-c" ]]; then
        local file=$(docker inspect  $(dcc ps -q )| grep -G '"LogPath": "*"' | sed -e 's/.*"LogPath": "//g' | sed -e 's/",//g')
    elif [[ $1 == "-a" ]]; then
        local file=$(docker inspect  $(docker ps -aq )| grep -G '"LogPath": "*"' | sed -e 's/.*"LogPath": "//g' | sed -e 's/",//g')

    else 
        local file=$(docker inspect "${PWD##*/}_$1_1" | grep -G '"LogPath": "*"' | sed -e 's/.*"LogPath": "//g' | sed -e 's/",//g')
    fi
    
    if [[ "$(uname)" == "Darwin" ]]; then
        docker-machine ssh dev sudo rm $file
    else
        rm $file
    fi
}

#Carefull with this one!
dclearvolumes(){
    docker volume rm $(docker volume ls -qf dangling=true)
}

dcmcreate(){
     docker-machine create --driver virtualbox 
}


#Make sure you have docker completions:
# - https://docs.docker.com/compose/completion/
# - https://docs.docker.com/machine/completion/

#Set up bash completions

#Helper
function make-completion-wrapper () {
    local function_name="$2"
    local arg_count=$(($#-3))
    local comp_function_name="$1"
    shift 2
    local function="
    function $function_name {
      ((COMP_CWORD+=$arg_count))
      COMP_WORDS=( "$@" \${COMP_WORDS[@]:1} )
      "$comp_function_name"
      return 0
    }"
    eval "$function"
    #echo $function_name
    #echo "$function"
}

#Completion definitions


make-completion-wrapper _docker_compose _dcc docker-compose
complete -F _dcc dcc

make-completion-wrapper _docker_machine _dcm docker-machine
complete -F _dcm dcm

make-completion-wrapper _docker_compose _dclog docker-compose logs
complete -F _dclog dclog

#We can use the same as for dcc logs, because we need container names
make-completion-wrapper _docker_compose _dclog docker-compose logs
complete -F _dclog dcdellogs

#We can use the same as for dcc logs, because we need container names
make-completion-wrapper _docker_compose _dclog docker-compose logs
complete -F _dclog dcexec

#We can use the same as for dcc logs, because we need container names
make-completion-wrapper _docker_compose _dcrebuild docker-compose logs
complete -F _dcrebuild dcrebuild
# credits: 
#  - https://passingcuriosity.com/2013/dnsmasq-dev-osx/
#  - http://stackoverflow.com/questions/33711357/how-to-auto-configure-hosts-entry-for-multiple-docker-machine-vms-os-x?answertab=votes#tab-top
#  - http://ubuntuforums.org/showthread.php?t=733397

