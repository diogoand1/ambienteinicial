#!/bin/bash
if [ $USER != 'root' ]
then
	echo 'É PRECISO EXECUTAR COMO ROOT, (sudo ./script.sh)'
	exit
fi

echo 'INÍCIO DA INSTALAÇÃO'
echo 'UPDATE'
apt-get update
echo 'ATUALIZADO INSTALAR APACHE, PHP5.4, MYSQL'
apt-get install php5 php5-cli php5-common php5-curl php5-memcached php5-mysql php5-gd php5-dev php-pear php-apc php5-dev make automake apache2 mysql-server mysql-client vim openjdk-7-jre zend-framework-bin memcached curl git gitk wine1.4-i386 -y
cd /usr/share/php/libzend-framework-php
cp Zend ../ -R
echo 'INSTALADO O LAMP, JAVA JDK e ZEND'
echo "INSTALANDO O PHPUNIT E DOCTRINE"
pear channel-discover pear.phpunit.de
pear install --onlyreqdeps phpunit/PHPUnit
pear channel-discover pear.doctrine-project.org
pear install --onlyreqdeps doctrine/DoctrineORM-2.3.2
echo ''

echo 'CRIANDO AS PASTAS DE PROJETOS'
echo ''
cd $HOME'/var/www'
mkdir 'projetos'
DIRPROJETOS=$HOME'/projetos'
cd $DIRPROJETOS
echo 'DIGITE O NOME DO PROJETO EM CAIXA BAIXA SEM ESPAÇOS'
read PROJETO
if [ -z $PROJETO ]
then
	echo "NÃO FOI DIGITADO O NOME DO PROJETO"
	exit
fi

DIRPROJETO="$DIRPROJETOS/$PROJETO"

zf create project $PROJETO
cd $DIRPROJETO
echo ''
echo 'DIGITE A SENHA DO USUARIO ROOT MYSQL E TECLE ENTER: '
read PASSWORD
if [ -z $PASSWORD ]
then
	echo "NÃO FOI DIGITADO A SENHA DO MYSQL ROOT"
	exit
fi
mysql -uroot -p$PASSWORD -e "CREATE DATABASE IF NOT EXISTS $PROJETO CHARACTER SET utf8 COLLATE utf8_general_ci;"
echo "BANCO DE DADOS $PROJETO CRIADO"
echo ''
zf configure db-adapter "adapter=PDO_MYSQL&host=localhost&username=root&password=$PASSWORD&dbname=glunme&charset=utf8"

echo 'INSTALANDO O COMPOSER'
curl -s https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

echo ''
echo "AJUSTANDO O HOST LOCAL PARA ACESSAR, http://local.$PROJETO"
cd /etc/
echo "127.0.0.1		local.$PROJETO" >> hosts
HOSTPROJETO="<VirtualHost *:80>\n
\tServerName local.$PROJETO\n
\tDocumentRoot $DIRPROJETO/public\n
\t<Directory $DIRPROJETO/public>\n
\t\tDirectoryIndex index.php\n
\t\tAllowOverride All\n
\t\tOrder allow,deny\n
\t\tallow from all\n
\t</Directory>\n
</VirtualHost>
"
cd /etc/apache2/sites-available
echo -e $HOSTPROJETO > $PROJETO
a2ensite $PROJETO
a2enmod rewrite
service apache2 restart

echo 'DIGITE O NOME DE USUÁRIO QUE ESTÁ LOGADO: '
read USUARIO
if [ -z $USUARIO ]
then
echo 'NÃO FOI DIGITADO O USUÁRIO, NÃO FOI POSSÍVEL MUDAR O DONO DA PASTA'
exit
fi
chown $USUARIO:$USUARIO $DIRPROJETOS/* -R

echo "CONCLUÍDO!\n A PASTA DO PROJETO ESTÁ EM $DIRPROJETO\n ACESSO http://local.$PROJETO"


