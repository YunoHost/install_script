# Script

## Prérequis

Afin de pouvoir récupérer le script install_yunohost, il faut avoir git d'installé sur votre machine.

Pour l'installer sur une distribution Debian:

    # apt-get install git

ou

    $ sudo apt-get install git

## Récuperation du script

Placez vous tout d'abord dans le répertoire /tmp:

    $ cd /tmp

Récupérez le script grâce à git:

    $ git clone https://github.com/YunoHost/install_script.git

Déplacez vous dans le répertoire Script nouvellement cloné:

    $ cd install_script/

Rendez le script install_yunohost exécutable:

    $ chmod o+x install_yunohost

Exécutez le script:

    $ ./install_yunohostv1

ou

    $ ./install_yunohostv2


Le script va automatiquement lancer l'installation de yunohost sur votre poste ainsi que tous les paquets nécessaires. Répondez simplement aux questions qui vous seront posées.
