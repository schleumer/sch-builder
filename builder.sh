#!/bin/sh

X_NAME=$1
X_HOST="schleumer.com.br"
X_SSH_HOST="schleumer.com.br"
X_LOG_DIR="\${APACHE_LOG_DIR}"
X_GIT_DIR="/var/git"
X_VHOSTS_DIR="/etc/apache2/sites-enabled"
X_WWW_DIR="/var/www"
X_SERVER_RELOAD="service apache2 reload"
X_SERVER_ADMIN="webmaster"
X_WWW_CHMOD=777

#default framework git name
# user/project
# example:
#  cakephp/cakephp
# this will make download project's zípball from github
X_CLONE_FRAMEWORK=$2

X_DEFAULT_VHOST=$(cat <<EOF
<VirtualHost *:80>\n
\tServerAdmin $X_SERVER_ADMIN@$X_NAME.$X_HOST\n
\tServerName $X_NAME.$X_HOST\n
\tDocumentRoot $X_WWW_DIR/$X_NAME\n
\t<Directory $X_WWW_DIR/$X_NAME>\n
\t\tOptions Indexes FollowSymLinks MultiViews\n
\t\tAllowOverride All\n
\t\tOrder allow,deny\n
\t\tallow from all\n
\t</Directory>\n
\tErrorLog $X_LOG_DIR/error.log\n
\tLogLevel warn\n
\tCustomLog $X_LOG_DIR/access.log combined
\n</VirtualHost>
EOF
)

X_GIT_POST_RECEIVE_HOOK=$(cat <<EOF
#Add these commands to the file \n
echo \"\\\\n\"\n
echo \"********************\"\n
echo \"Post receive hook: Updating website\"\n
echo \"********************\"\n
echo \"\\\\n\"\n

#Change to working git repository to pull changes from bare repository\n
cd $X_WWW_DIR/$X_NAME || exit\n
unset GIT_DIR\n
git pull origin master\n
#End of commands for post-receive hook\n
echo \"\\\\n\"\n
EOF
)

# Check first arg for project name
if [ -z "$1" ]
then
	printf "\nVocê precisa inserir o nome do projeto";
else
	if [ -d "$X_GIT_DIR/$X_NAME" ]
	then
		printf "\nJá existe um Projeto GIT com esse nome na past /var/git/$X_NAME"
		exit
	fi
	if [ -d "$X_WWW_DIR/$X_NAME" ]
	then
		printf "\nJá existe um Projeto WEB com esse nome na pasta /var/www/$X_NAME"
		exit
	fi
	if [ ! -d "$X_GIT_DIR" ]
	then
		mkdir "$X_GIT_DIR"
	fi
	cd "$X_GIT_DIR"
	printf "\n####CRIANDO REPOSITÓRIO GIT EM MODO BARE \n"
	git init --bare $X_NAME
	printf "\n####CRIANDO HOOK DE POST RECEIVE DENTRO DO REPOSITÓRIO GIT \n"
	echo $X_GIT_POST_RECEIVE_HOOK > "$X_GIT_DIR/$X_NAME/hooks/post-receive"
	printf "\n####DANDO PERMISSÕES AO HOOK PARA SER EXECUTADO \n"
	chmod +x "$X_GIT_DIR/$X_NAME/hooks/post-receive"
	printf "\n####CLONANDO NO PROJETO WEB \n"
	mkdir -p "$X_WWW_DIR/$X_NAME"
	cd "$X_WWW_DIR"
	git clone "file://$X_GIT_DIR/$X_NAME" "$X_NAME"
	printf "\n####CRIANDO VHOST NO APACHE\n"
	echo $X_DEFAULT_VHOST > "$X_VHOSTS_DIR/$X_NAME.conf"
	printf "\n####RECARREGANDO CONFIGURAÇÕES DO APACHE\n"
	
	if [ -z "$2" ]
	then
	    printf "\nVocê não optou por utilizar um framework\n"
	else
	    cd "$X_WWW_DIR/$X_NAME"
	    printf "\n####DOWNLOADING $2 ZIPBALL\n"
	    wget "https://github.com/$2/archive/master.zip"
	    if [ -e "master.zip" ]
	    then
	        unzip "master.zip"
	        rm  "master.zip"
	        #yet another pokemon reference
	        master_zipball=$(printf $2 | sed 's/.*\///g')
		FILES_ON_ZIP=$(ls $master_zipball-master/ -a | sed "s#^#"${PWD}"/$master_zipball-master/#g" | grep -v "\.$\|\.$") 
	        mv $FILES_ON_ZIP "$X_WWW_DIR/$X_NAME"
		chmod $X_WWW_CHMOD $X_WWW_DIR/$X_NAME -R
	        rm $master_zipball-master -rf
	    else
	        printf "\nError downloading zipball"
	    fi
	fi

	$X_SERVER_RELOAD

	printf "\n####It's all done. Back to work!\n"
	printf "\n\tProject Folder: $X_WWW_DIR/$X_NAME"
	printf "\n\tGit Folder Folder: $X_GIT_DIR/$X_NAME"
	printf "\n\tGit Clone: git clone ssh://$X_SSH_HOST:$X_GIT_DIR\n"
fi



