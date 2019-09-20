#!/usr/bin/perl
################################################################################
# SCRIPT modify_item_data.pl
# DESCRIPTION : ce script lit en entrée des fichiers xml contenant la 
# notice complète d'un exemplaire, depuis le biblio jusqu'à l'exemplaire propre-
# ment dit. Il modifie ces informations puis écrit un ordre de mise à jour de
# l'exemplaire
# SORTIE : un fichier par item.
################################################################################
use strict;
use warnings;
use utf8;
use POSIX qw(strftime);
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({ 
	level => $TRACE, 
	file => ":utf8> modify_item_data.log" 
});
use XML::Twig;

# Clef API en écriture sur le bac à sable
#my $APIKEY = 'l8xx6d859dd63ee94cf9981a4911c99f8aa1';
my $adresse_api = 'https://api-eu.hosted.exlibrisgroup.com/almaws/v1/bibs/mms_id/holdings/holding_id/items/item_pid';
# Création d'un dictionnaire faisant correspondre les codes-barres et les descriptions
# ####################################################################################
my %cb2description;
my ($entry_file, $APIKEY) = @ARGV;
if (not defined $entry_file or not defined $APIKEY) {
	  die "Indiquez en entrée (1)un fichier contenant les codes barres et la description et (2) la clef API";
}
else {
    TRACE "Fichier traité : $entry_file\n";
}
open ( FILE_IN, "<", $entry_file) || die "Le fichier $entry_file est manquant\n";
binmode FILE_IN, ":utf8";
while (<FILE_IN>)
{ 
	chomp;
	my ($key, $val) = split /\|/;
	# Si jamais un code barre apparaît deux fois, on n'a pas le choix : il faut
	# écraser avec la dernière valeur trouvée.
	# #########################################################################
	TRACE $key;
	$cb2description{$key} = $val; 
}
close(FILE_IN);

my $mms_id;
my $holding_id;
my $item_pid;

# Main
{
	# Traitement des exemplaires concernées un par un.
	# ################################################
	my $repertoire = "./items-xml/";
	opendir my($rep), $repertoire;
	my @files = readdir $rep;
  foreach my $FILE_NAME (@files) 
	{
		if (($FILE_NAME ne '..') and ($FILE_NAME ne '.') and ($FILE_NAME ne 'traites') and ($FILE_NAME ne 'log'))
		{
		  my $fichier_xml = $repertoire . $FILE_NAME;
		  TRACE "Fichier traité : $fichier_xml\n";
	    # Lecture des informations récupérées d'Alma. C'est un arbre XML.
	    # ###############################################################
	    my $twig= new XML::Twig( 
				    output_encoding => 'UTF-8',
		        twig_handlers =>                     # Handler sur le tag 
		          { item_data => \&item_data,        # Sur l'item
								holding_data => \&holding_data,  # sur la holding
								bib_data => \&bib_data }         # sur la notice bib
            );                               

	    $twig->parsefile($fichier_xml);

			# Construction de l'ordre API à envoyer à Alma.
			# #############################################
			#TRACE "--> MMS ID : $mms_id\n";
			#TRACE "--> HOLDING ID : $holding_id\n";
			#TRACE "--> PID : $item_pid\n";

			# $twig->print(pretty_print=>'indented');
      my $sortie = $twig->sprint;               # C'est le XML a envoyer dans Alma après les modifications
			$sortie =~ s/"/\\"/g;                     # Il faut y protéger les double quotes
			$sortie =~ s/\n//g;                       # et y retirer les \n.
			my $temp_adresse_api = $adresse_api;
			$temp_adresse_api =~ s/mms_id/$mms_id/g;           # Mettre l'identifiant de la bib dans l'appel API
			$temp_adresse_api =~ s/holding_id/$holding_id/g;   # Mettre l'identifiant holding dans l'appel API
			$temp_adresse_api =~ s/item_pid/$item_pid/g;       # Mettre l'identifiant item dans l'appel API

			my $ordre_api = 'curl -X PUT "'. $temp_adresse_api . '?apikey=' . $APIKEY . '" -H  "accept: application/xml" -H  "Content-Type: application/xml" -d "';
			$ordre_api = $ordre_api . $sortie . "\" > log/modified" . $FILE_NAME . ".log";
			#TRACE "--> Ordre API à envoyer à Alma : $ordre_api\n";

			# Enregistrement de l'ordre dans un fichier.
			# ##########################################
	    open (my $file_out, ">", "./items-xml-modified/modified-".$FILE_NAME) || die "Impossible d'ouvrir le fichier de sortie temporaire\n";
			binmode $file_out, ":utf8";
			print $file_out $ordre_api;
	    close($file_out);
			#TRACE "--> Ordre API enregistré dans le fichier.\n";
			#TRACE "Fin de traitement du fichier --------------------\n";
    }
  }
}

# Remplacement de la description dans le flux XML
# ###############################################
sub item_data {
	my ($twig, $item_data)= @_;
	#my @test=$item_data->children;     # Liste des balises dans item_data
	#foreach my $test (@test)           
	#{ $test->print;               
	#  print "\n"; 
	#}
	my $barcode = $item_data->first_child('barcode')->text ;
	TRACE "--> Code barre : $barcode\n";
	# Il faut retirer le premier caractère de la description si ce n'est pas un caractère [0-z]
  (my $description = $cb2description{$barcode}) =~ s/,//;	
	TRACE "--> Description : $description";
	$item_data->first_child('description')->set_text($description);

	$item_pid =   $item_data->first_child('pid')->text;
}

# Récupération du holding id et autres opérations de holding
# ##########################################################
sub holding_data {
	my ($twig, $holding_data)= @_;
	$holding_id = $holding_data->first_child("holding_id")->text();
	$holding_data->first_child("temp_policy")->set_text("");
	TRACE "--> Suppression de la valeur d'exception de circulation\n";
}
 
# Récupération du mms_id
# ##########################################################
sub bib_data {
	my ($twig, $bib_data)= @_;
	$mms_id = $bib_data->first_child("mms_id")->text();
}
