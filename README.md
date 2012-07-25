Script
======

Sur votre machine, installez git : apt-get install git si vous êtes sur debian ou sudo apt-get install git


Récupérez ensuite le script d'installation Placez vous dans le dossier "/tmp" et récupérez le script:
cd /tmp
git clone https://github.com/YunoHost/Script.git

Allez dans le dossier "Script", rendez exécutable le script d'installation et exécutez le :
cd Script/
chmod o+x install_yunohost
./install_yunohost

Le script va automatiquement lancer l'installation de yunohost sur votre poste ainsi que tous les paquets nécessaires. Répondez simplement aux questions qui vous seront posés.
