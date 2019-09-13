#!/usr/bin/env bash
MODE=${1?Erreur : choisissez un mode, soit INIT, soit GET, soit MODIFY}
case $MODE in
	INIT)
		# Nettoyage ou création des répertoires nécessaires
		if [ -d "./items-xml" ]; then
			echo "Nettoyage de ./items-xml"
			for file in ./items-xml/*.tmp
			do
			  rm $file
			done
		else
			echo "Création de ./items-xml"
			mkdir ./items-xml
		fi

		if [ -d "./items-xml-get" ]; then
			echo "Nettoyage de ./items-xml-get"
			for file in ./items-xml-get/*.tmp
			do
			  rm $file
			done
		else
			echo "Création de ./items-xml-get"
			mkdir ./items-xml-get
		fi

		if [ -d "./items-xml-modified" ]; then
			echo "Nettoyage de ./items-xml-modified"
			for file in ./items-xml-modified/*.tmp
			do
			  rm $file
			done

			if [ -d "./items-xml-modified/log" ]; then
				echo "Nettoyage de ./items-xml-modified/log"
			  for file in ./items-xml-modified/log/*.tmp
			  do
			    rm $file
			  done
			else
				echo "Création de ./items-xml-modified/log"
        mkdir ./items-xml-modified/log
			fi

		else
			echo "Création de ./items-xml-modified et de ./items-xml-modified/log"
			mkdir items-xml-modified
      mkdir ./items-xml-modified/log
		fi
		echo "L'environnement est initialisé"
		echo "Procédure :"
		echo "1. Lancez perl get_item_data.pl"
		echo "2. Rendez exécutable les fichiers dans ./items-xml-get"
		echo "3. Relancer execute_api.bash en mode GET"
		echo "4. Lancer perl modify_item_data.pl"
		echo "5. Rendez exécutable les fichiers dans ./items-xml-modified"
		echo "6. Relancer execute_api.bash en mode MODIFY"
		echo "7. Vérifiez les résultats dans Alma."
		;;
	GET)
		# On se place dans le répertoire où se trouve les appels à l'API 
		# qui va chercher le détail d'un exemplaire.
		# Attention : les fichiers .tmp doivent être exécutables !
		cd ./items-xml-get
		for file in *.tmp
		do
			chmod u+x $file
			msg=`./$file 2>&1`
			if [ $? -eq 0 ]
			then
				echo "--> Succès sur '$file' bien exécuté (code retour $?)"
			else
			  echo -e "--> Erreur sur '$file'\n----> Code retour $?\n----> Message : $msg"
			fi
		done
		# J'efface tous les fichiers résultats restés vides qui corresponent aux cas d'erreur
		cd ../items-xml
		find . -size 0c -delete 
		echo "Tous les fichiers ont été traités. Vérifiez les messages d'erreurs pour savoir si l'un d'entre eux a posé problème."
		;;
	MODIFY)
		# On se place dans le répertoire où se trouve les appels à l'API
		# qui modifie le détail d'un exemplaire
		# Attention : les fichiers .tmp doivent être exécutables !
		cd ./items-xml-modified
		for file in *.tmp
		do
			chmod u+x $file
			msg=`./$file 2>&1`
			if [ $? -eq 0 ]
			then
				echo "--> Succès sur '$file' bien exécuté (code retour $?)"
				mv ./$file traites
			else
			  echo -e "--> Erreur sur '$file'\n----> Code retour $?\n----> Message : $msg"
			fi
		done
		echo "Tous les fichiers ont été traités. Vérifiez les messages d'erreurs pour savoir si l'un d'entre eux a posé problème."
		;;
	*)
		echo "Le paramètre donné est invalide :"
		echo "--> Valeurs possibles :"
		echo "----> GET : pour exécuter les fichiers qui sont dans items-xml-get"
		echo "----> MODIFY : pour exécuter les fichiers qui sont dans items-xml-modified"
		echo "----> INIT : initalisation des répertoires de travail"
		echo "Fin de programme"
		;;
esac
exit 0
