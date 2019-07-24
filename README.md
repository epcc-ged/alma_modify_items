# alma_modify_items

### Objectif
Les programmes utilisés ici permettent de mettre à jour les descriptions d'exemplaires dans Alma sur la base d'une liste de codes-barres et de descriptions correspondantes fournis en entrée du premier des scripts.

### Description

Le processus s'effectue en plusieurs étapes et nécessite de disposer d'un fichier type csv (séparateur nécessaire : **|** - et pas **;** ) comportant en première colonne les codes-barres d'exemplaires et en seconde colonne la valeur à mettre en description. Ce fichier doit se nommer **`barcode-items.txt`**.

Ce fichier disponible, il faut le placer dans le même répertoire que les scripts Perl. Dans ce répertoire, il faut créer deux sous-répertoires : **`items-xml`** et **`items-xml-modified`**.

#### 1. Script get_item_data.pl
Lancement du script : `perl get_item_data.pl`

Entrée : fichier `barcode-items.txt`

Sortie : fichier `items.tmp` 

Description : pour chaque ligne dans `barcode-items.txt`, le script écrit un ordre curl faitsant un appel à l'API Alma retrouvant un exemplaire sur la base du code-barre (voir ci-dessous). Cet ordre est écrit dans le fichier `items.tmp`. A la fin du script, on a autant d'ordre curl dans le fichier que de codes-barres dans le fichier `barcode-items.txt`.

#### 2. Exécuter `items.tmp`
Les ordres contenues dans `items.tmp` doivent être exécutés. Il faut donc rendre ce fichier exécutable et le lancer.
L'API Alma appelé est `https://api-eu.hosted.exlibrisgroup.com/almaws/v1/items?view=label&item_barcode=CODEBARRE` qui renvoie un flux XML pour l'exemplaire dont le code-barre est CODEBARRE (paramètre). Le résultat est stocké dans un fichier `items-xml/CODEBARRE.xml`

#### 3. Script `modify_item_data.pl`
Lancement du script : `perl modify_item_data.pl`

Entrée : contenu du répertoire `items-xml` et fichier `barcode-items.txt`

Sortie : fichiers dans le répertoire `items-xml-modified`

Description : ce script prend chaque fichier XML trouvé dans `items-xml`, y modifie la description, y retire l'exception de circulation puis écrit un ordre curl appelant l'API Alma modifiant un exemplaire. Cet ordre est placé dans un fichier situé dans le répertoire `items-xml-modified`. L'API est `"https://api-eu.hosted.exlibrisgroup.com/almaws/v1/bibs/BIB_ID/holdings/HOLDING_ID/items/ITEM_PID`.

#### 4. Exécuter les fichiers contenus dans `items-xml-modified`
Ces fichiers mettent à jour les exemplaires dans Alma. 

### Remarque
Les deux scripts Perl produisent des fichiers .log donnant le détail des opérations réalisées.


### A faire
- Passage en paramètre du nom du fichier de codes-barres plutôt que d'imposer le nom.
- Effacement des répertoires (et éventuellement leur création) au démarrage des programmes.
- Script bash qui exécute les fichiers produits contenant les commandes curl vers Alma.
