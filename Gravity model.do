
/*                                    */


/*============================================================================================================================*/
/*                               PREMIERE PARTIE: PREPARATION ET MANIPULATIONS DE DONNEES                                     */
/*============================================================================================================================*/


/* Pour construire une equation de gravité on a besoin des données suivante dans une seule table :
 1) Les distances entre pays exportateurs et importateurs 
 2) Les PIBs des pays 
 3) Les valeurs du commerce bilatérales.
Ces données vous sont fournies. Les distances et les PIB sont dans le fichier excel "total". Le commerce est dans la 
base baci_afr.
Créer un dossier sur votre disque T, mettez vos données dedans. Ce dossier stata constituera votre espace de travail.
Toutes les données et futurs résultats seront stockés dans ce fichier
Dans ce meme dossier, vous pourrez sauvegarder toutes vos lignes de commande (votre script). Dans le language STATA, on utilise l'expression "do-file" ou "do". votre do-file vous permettra de retrouver 
les résultats précédement obtenus.  
*/


clear all

* definissons notre espace de travail 

cd "C:\Users\Boubacar\Desktop\Stata"   

******* importation des données necessaire à la construction de notre table : Avec Stata, on ne peut afficher qu'une table à la fois 

***les distances
  
import excel "total.xls", sheet("dist") firstrow clear
/* 
Observez la base de donnnées dist. 
Dans cette base, il y a plusieurs informations qui ne nous intéressent pas, 
Gardons uniquement les noms des pays et les distances.
*/
keep isoi isoj dist
save dist , replace 

  ***les PIBs

import excel "pib.xls", sheet("Data") firstrow clear

/* 
Observez la base de donnnées pib. 
Chaque année représente une colonne, or on souhaiterait qu'il n'y ait qu'une seule colonne année
*/
reshape long year_, i(CountryCode) j(t)

****les valeurs des pibs sont contenu dans la variable year_ tandis que les années sont dans la variable t. Renommons donc la variable year_ par pib
rename year_ pib 
drop IndicatorName IndicatorCode
save pib , replace 

/* Nous venons de mettre les tables de distance et de pib en format STATA. Desormais nous avons les trois tables necessaires à la construction de notre table final.
pour ce faire, nous allons dans un premier temps, fusionner la base de distance (dist) et celle de commerce (baci_afr) pour avoir ces deux variables dans une mÃªme table.
Cependant, nous faisons face à un premier problème:

Une fusion nécessite de définir une clé de fusion, c'est à dire une colonne de référence commune aux deux tables à fusionner qui 
permet de créer une correspondance entre les deux jeux de données. Dans notre cas, il s'agit du code code de référence des pays.
Or,
dans la base baci_afr, les pays sont nommés par des nombres,
alors que dans la base "dist" ils sont nommés uniquement par des lettres.
Pour fusionner les deux tables il nous faut une table de correspondance.
Cette table de correspondance est dans le fichier "total", elle se nomme correspays
Il nous faut l'importer sous STATA*/

import excel "C:\Users\fcanda01\Desktop\cours\Flux_com\Stata\total.xls", sheet("correspays") firstrow clear

/* Observez cette base
la variable iso_old ne nous sera d'aucune utilité, enlevons là à l'aide de la commande drop.
toutes les observations sont en couleur rouge. Dans le language stata on dit qu'lle sont declarées en format 
string c'est à dire que les observations comportent un ou plusieurs caractères qui sont des letres. Declarons celles qui ont une apparence numerique en format numerique afin 
de pouvoir merger(fusionner) la table de correspondance et celle de distance. On utilise la commande destring*/

destring iso iso_old , replace
drop iso_old

/* Nous faisons face à un second problème:
la colonne des pays est nommée suivant différents noms ou "labels" dans chacune des tables.
or pour fusionner il faut que la clé de fusion (=le code pays) ait le même nom dans les deux tables. 
Nous modifions donc la base des correspondances*/

rename iso i
label variable i "code numerique des pays exportateurs"
rename L3 isoi
label variable isoi "code alphanumerique des pays exportateurs"

/**** notre clef de fusion comporte des doubons. supprimons les ***/

duplicates drop isoi , force
save correspays , replace
/* Nous pouvons désormais fusionner les tables distance et de correspondance */

merge 1:m isoi using dist , keep(match)

/* il est important de noter que les noms des pays "country" sont ceux de i
nous allons donc renommer cette colonne*/
rename country countryi
label var countryi "Noms des pays exportateurs"
drop _merge

save dist1 , replace

 
/******************************** Verifications *************************************************/
/************************************************************************************************/

/*A chaque merge il faut que vous vérifiez combien de valeurs sont perdues par manque de donnÃ©es dans l'une des deux tables.
En effet, puisque la fusion est effectué sur les observations communes aux tables, le reste des observations est effacée 
dans la table de sortie grace à l'option keep(match). 
L'un des moyens de vérifier la proportion d'obs disparues est de refaire la meme procédure sans l'option keep puis de regarder la sortie dans le journal.*/ 

use correspays , clear
merge 1:m isoi using dist
keep if _merge == 2  
/**** on remarque que 12 observations provenant de la première table (correspays ; appelé master dans le language STATA) 
n'ont pas trouvé de correspondance dans la table des distances. 1568 observation provenant de la table des distances n'on pas trouvÃ© de correspondance dans la table correspays
ce qui correspond aux distances de 7 pays.**/

/***** A ce stade , nous avons uniquement les codes chiffrés des pays exportateurs (i). Faisons donc la meme procedure pour les pays importateurs****/

use correspays , clear
rename i j
lab var j "code numerique des pays importateurs"
rename isoi isoj
label variable isoj "code alphanumerique des pays importateurs"

merge 1:m isoj using dist1 , keep(match)
rename country countryj
label var countryj "Noms des pays importateurs"
drop _merge
save dist , replace /***** notre table de distance comporte maintenant des codes pays nombre ****/


/****rappelons que notre objectif  est d'avoir une table finale sur laquelle lancé des estimations: laquelle table doit comporter 
des distances à coté de la valeur du commerce****/

/****joignons donc notre table de commerce avec les distances: cependant en observant notre base de commerce 
on constate qu'elle est par pays produit et par année or la dimension produit ne nous interesse pas. Ce qui nous interesse c'est d'avoir le commerce total d'un pays i vers un pays j a une annÃ©e donnÃ©.
pour ce faire on peut sommer la valeur des exportation par couple de pays***/ 

use BACI_AFR , clear
collapse (sum) v , by(i j t)

** fusionnons la table de commerce et celle de distance
merge m:1 i j using dist , keep(match)
drop _merge 
save merge1 , replace 

/***** la table merge1 est la table combinée du commerce et de la distance***/

/****n'oublions pas que notre équation à estimer comporte les pibs des pays i et aussi ceux des pays j: il faut donc les ajouter à notre table merge1****/

/**renommons les variables de notre table pib afin de pouvoir la merger avec la table merge1 ***/

use pib , clear
rename CountryCode isoi
lab var isoi "code alphanumerique des pays exportateurs"
rename pib pibi
lab var pibi "pib des pays exportateurs"
drop CountryName 

merge 1:m isoi t using merge1 , keep(match)
drop _merge
save merge1 , replace

use pib , clear
rename CountryCode isoj
lab var isoj "code alphanumerique des pays importateurs"
rename  pib pibj
lab var pibj "pib des pays importateurs"
drop CountryName 

merge 1:m isoj t using merge1 , keep(match)
drop _merge
save table_final , replace


/*============================================================================================================================*/
/*                                         DEUXIEME PARTIE: PREMIERE REGRESSION ECONOMETRIQUE                                                */
/*============================================================================================================================*/

/* Pour utiliser la méthode des MCO sur notre relation de gravité, on linearise l'equation en passant les variables en log
Notez que les pib etant exprimes en dollars et les flux commerciaux en milliers de dollars, il est necessaire de les convertir dans la meme unite*/

gen lyi = ln(pibi)
gen lyj = ln(pibj)
gen ldist = ln(dist)
gen ltrade = ln(v*1000)

regress ltrade ldist lyi lyj 
reg ltrade ldist lyi lyj , vce(robust)

/*============================================================================================================================*/
/*                                         DEUXIEME PARTIE: DEUXIEME REGRESSION ECONOMETRIQUE AVEC DES EFFETS FIXES PAYS                                               */
/*============================================================================================================================*/

**** creation d'effets fixes ( il existe plusieurs facon de créer des effets fixes)

***** methode 1

tab i , gen(EXP)
tab j , gen(IMP)
drop EXP*
drop IMP*

**** methode 2

qui tab i , gen(EXP)
qui tab j , gen(IMP)
drop EXP*
drop IMP*

**** methode 3

xi i.i
renpfix _Ii_ i

xi i.j
renpfix _Ij_ j

egen ij = concat(i j)

reg ltrade ldist lyi lyj i24-i894 j24-j894 , vce(robust)
reg ltrade ldist lyi lyj i24-i894 j24-j894 , cluster (ij)
ppml v ldist lyi lyj i24-i894 j24-j894 , cluster (ij)

