Static Website Example
----------------------

To be used with Cloud Academy labs.


License
----------------------

This static website is based on the Dimension template by [HTML5 UP](https://html5up.net/)

Creative Commons License
All of the site templates I create for [HTML5 UP](https://html5up.net/) are licensed under the Creative Commons Attribution 3.0 License, which means you can:
 - Use them for personal stuff
 - Use them for commercial stuff
 - Change them however you like


... all for free, yo. In exchange, just give HTML5 UP credit for the design and tell your friends about it :)

More info [here](https://html5up.net/license).

CI/CD Jenkins
-------------

Dépôt : https://github.com/alvirranyadja/static-website.git
Jenkins : 16.192.73.184. Déploiement nginx : 16.192.253.80.

Le Jenkinsfile charge la bibliothèque partagée de ce dépôt (`vars/`, `src/`, `resources/`) puis enchaîne :

1. Checkout
2. Build — assemble `dist/build` et `build-info.json`
3. Acceptance — sections, formulaire, page 404, médias, manifeste, liens
4. Security — secrets, hôtes approuvés, clé SSH épinglée, en-têtes nginx, sudo limité
5. Package — artefact `dist/site-<build>.tar.gz` et empreinte `.sha256`
6. Archive — artefacts conservés dans Jenkins
7. Deploy — SSH vers 16.192.253.80, bascule atomique, rechargement nginx
8. Functional test — HTTP, médias, en-têtes. Retour arrière si échec

Préparation de 16.192.253.80 (une fois, en root) :

    sudo bash deploy/bootstrap-deploy-host.sh

Puis autoriser la clé Jenkins dans `/home/deploy/.ssh/authorized_keys`.

Dans Jenkins (16.192.73.184) : credential « SSH Username with private key », id `deploy-ssh-key`, username `deploy`.
Job : Pipeline script from SCM, Script Path `Jenkinsfile`.
Plugins : Git, Pipeline, SSH Agent.

Groupes de sécurité : 16.192.73.184 vers 16.192.253.80 sur les ports 22 et 80, et le port 80 ouvert aux visiteurs.
La clé d'hôte de la machine de déploiement est épinglée dans `deploy/known_hosts`.
