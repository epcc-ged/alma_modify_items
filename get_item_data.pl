#!/usr/bin/perl
################################################################################
# SCRIPT get_item_data.pl
# DESCRIPTION : ce script lit en entrée un fichier contenant des codes-barres
# d'exemplaires ainsi qu'un champ qu'on nommera description associé au code-
# -barre. Pour chaque code-barre lu, le script écrit un ordre d'appel à une API
# d'Alma qui renverra un arbre XML contenant le détail de l'item.
# SORTIE : un fichier par item dans un répertoire wget-xml-get
################################################################################
use strict;
use warnings;
use utf8;
use POSIX qw(strftime);
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({ 
	level => $TRACE, 
	file => ":utf8> get_item_data.log" 
});

# Clef API en écriture sur le bac à sable
my $APIKEY = 'l8xx6d859dd63ee94cf9981a4911c99f8aa1';

# Sous-routine pour vérifier le début des codes-barres
######################################################
sub begins_with
{
	my $strtmp = '';
	my $retour = '';
	$strtmp=substr($_[0], 0, 2);
	$retour=$strtmp ~~ ['EB', 'AD', 'UL', 'TL', 'RE', 'Re'] ? 0 : 1;
	return $retour;
}

# Main
{
open ( FILE_IN, "<", "./barcode-items.txt") || die "Le fichier barcode-items.txt est manquant\n";
binmode FILE_IN, ":utf8";
my $bib_id = '';
my $holding_id = '';
my $item_id = '';
my $item_xml = '';

	while(<FILE_IN>)
	{
		# Découpage d'une ligne pour extraire le code-barre et la description.
		my $ligne = $_ ;
		chomp($ligne);
		my ($code_barre,$description) = split(/\|/, $ligne);

		# Ecrire un appel API pour récupérer les informations sur l'item. On ignore certains codes-barres néanmoins.
		if (begins_with($code_barre) == 1){
      open ( FILE_OUT, ">", "./items-xml-get/wget-items-" . $code_barre . ".tmp") || die "Impossible d'ouvrir le fichier de sortie temporaire\n";
      binmode FILE_OUT, ":utf8";
			print FILE_OUT "wget -O - -o /dev/null 'https://api-eu.hosted.exlibrisgroup.com/almaws/v1/items?view=label&item_barcode=" . $code_barre . "&apikey=" . $APIKEY  . "' > ../items-xml/" . $code_barre . ".tmp" . "\n";
			TRACE "Code barre $code_barre traité dans le fichier wget-items-$code_barre.tmp\n";
      close(FILE_OUT);
		}
		else {
			TRACE "Code-barre $code_barre non recevable\n";
		}
	}
close(FILE_IN);
}

