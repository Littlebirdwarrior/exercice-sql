-- 1. Nom des lieux qui finissent par 'um'.
SELECT * FROM `lieu` WHERE `nom_lieu` LIKE '%um'; 

-- 2. Nombre de personnages par lieu (trié par nombre de personnages décroissant).

SELECT `nom_lieu`,
COUNT(id_personnage) AS nombre_personnage --cree un alias de colonne qui compte les perso (grace au id)
FROM `personnage` 
INNER JOIN lieu ON lieu.id_lieu = personnage.id_lieu --récupère lieu et compare id_lieu de perso et id_lieu de lieu
GROUP BY personnage.id_lieu --ici, repréciser id_lieu dans personnage, sinon "group statement est ambigue"
ORDER BY nombre_personnage  DESC --Desc présente par ordre décroissant
;

-- 3. Nom des personnages + spécialité + adresse et lieu d'habitation, triés par lieu puis par nom de personnage.

-- Permet de contourner l'erreur #1 of SELECT list is not in GROUP BY clause and contains nonaggregated column 'XXXXX' which 
--is not functionally dependent on columns in GROUP BY clause; this is incompatible with sql_mode=only_full_group_by
-- depuis MySql 5.4, ne permet plus de selectionnner des champ qui ne sont pas agregé, se produit quand on risque de récupérer 2 choses nomée pareille
--any_value, prends la 1er valeur souhaité, group_concat, aggrege les case d'un colonne sur une ligne
-- soucre : https://grafikart.fr/tutoriels/only-full-group-by-sql-1206


SELECT ANY_VALUE(lieu.nom_lieu), GROUP_CONCAT(personnage.nom_personnage SEPARATOR ' | '), GROUP_CONCAT(personnage.adresse_personnage SEPARATOR ' | '), GROUP_CONCAT(specialite.nom_specialite SEPARATOR ' | ') 
FROM personnage
INNER JOIN lieu ON lieu.id_lieu = personnage.id_lieu
INNER JOIN specialite ON specialite.id_specialite = personnage.id_specialite
GROUP BY personnage.id_lieu, personnage.nom_personnage -- c'est la bonne requête

SELECT @@sql_mode -- permet afficher les mode, dont ONLY_FULL_GROUP_BY,
SET GLOBAL sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY','')); --permet de retirer ce monde, déconseillé


-- 4. Nom des spécialités avec nombre de personnages par spécialité (trié par nombre de personnages décroissant).

SELECT `nom_specialite`,
COUNT(id_personnage) AS nombre_personnage_par_specialite
FROM `personnage` 
INNER JOIN specialite ON specialite.id_specialite = personnage.id_specialite
GROUP BY personnage.id_specialite
ORDER BY nombre_personnage_par_specialite DESC
;


-- 5. Nom, date et lieu des batailles, classées de la plus récente à la plus ancienne (dates affichées au format jj/mm/aaaa).

SELECT nom_bataille, DATE_FORMAT(`date_bataille` , "%D %b %y") as date_bataille_formatee , nom_lieu
FROM bataille
INNER JOIN lieu ON lieu.id_lieu = bataille.id_lieu
ORDER BY date_bataille -- affiche ce qu'il faut

-- 6. Nom des potions + coût de réalisation de la potion (trié par coût décroissant).

SELECT potion.nom_potion, 
SUM(ingredient.cout_ingredient * composer.qte) AS cout_total_potion
FROM potion
INNER JOIN composer ON potion.id_potion = composer.id_potion
INNER JOIN ingredient ON ingredient.id_ingredient = composer.id_ingredient
GROUP BY potion.id_potion --plus juste que de prendre de composer, car c'est potion qui est dans le form
ORDER BY cout_total_potion DESC


-- 7. Nom des ingrédients + coût + quantité de chaque ingrédient qui composent la potion 'Santé'.

SELECT -- figurez vous que le SQL s'indente aussi, vdm
	potion.id_potion,
	potion.nom_potion,
	GROUP_CONCAT(ingredient.nom_ingredient SEPARATOR ' | ') AS ingredients,
	SUM(ingredient.cout_ingredient * composer.qte) AS cout_total_potion
FROM
	potion
	INNER JOIN composer ON potion.id_potion = composer.id_potion
	INNER JOIN ingredient ON ingredient.id_ingredient = composer.id_ingredient
WHERE
	potion.nom_potion = 'Santé' --selon les règle, un where est tjs avant un group by, on filtre les resultats avant de les grouper
GROUP BY
	potion.id_potion

-- 8. Nom du ou des personnages qui ont pris le plus de casques dans la bataille 'Bataille du village gaulois'.

SELECT
	bataille.nom_bataille,
	personnage.nom_personnage,
	prendre_casque.qte
FROM 
	bataille
	INNER JOIN prendre_casque ON bataille.id_bataille = prendre_casque.id_bataille --ordre de l'égalité n'a pas d'importance
	INNER JOIN personnage ON personnage.id_personnage = prendre_casque.id_personnage
WHERE
	bataille.nom_bataille = 'Bataille du village gaulois'
GROUP BY
	bataille.id_bataille -- ok !


-- 9. Nom des personnages et leur quantité de potion bue (en les classant du plus grand buveur au plus petit).

SELECT 
	personnage.nom_personnage,
	SUM(dose_boire) AS quantite_bue
FROM 
	personnage
	INNER JOIN boire ON personnage.id_personnage = boire.id_personnage
GROUP BY
	personnage.id_personnage
ORDER BY
	quantite_bue DESC --Agecanonix fait clairement des exces


-- 10. Nom de la bataille où le nombre de casques pris a été le plus important.

SELECT
	bataille.nom_bataille,
	prendre_casque.qte AS quantite_casque
FROM 
	bataille
	INNER JOIN prendre_casque ON prendre_casque.id_bataille = bataille.id_bataille
GROUP BY
	bataille.id_bataille
ORDER BY quantite_casque DESC
LIMIT 1-- Limit permet de n'afficher que la 1er ligne, et donc la bataille ou le plus grand nombre de casque à été pris

-- 11. Combien existe-t-il de casques de chaque type et quel est leur coût total ? (classés par nombre décroissant)

SELECT
	casque.id_type_casque,
	GROUP_CONCAT(casque.nom_casque SEPARATOR ' | '),
	SUM(casque.cout_casque * prendre_casque.qte) AS cout_total_casque --multiplie le cout unitaire de chaque nom par sa quantité propre = SUM( prix unitaire * quantité)
FROM 
	casque
	INNER JOIN prendre_casque ON prendre_casque.id_casque = casque.id_casque
GROUP BY
	casque.id_type_casque
ORDER BY cout_total_casque DESC --ok


-- 12. Nom des potions dont un des ingrédients est le poisson frais.

SELECT
	potion.nom_potion,
	GROUP_CONCAT(ingredient.nom_ingredient SEPARATOR ', ')
FROM 
	potion
	INNER JOIN composer ON potion.id_potion = composer.id_potion
	INNER JOIN ingredient ON ingredient.id_ingredient = composer.id_ingredient
WHERE
	ingredient.nom_ingredient = 'Poisson frais'
GROUP BY 
	potion.nom_potion -- on ajoute un where pour filtrer et le tour est joué


-- 13. Nom du / des lieu(x) possédant le plus d'habitants, en dehors du village gaulois.

SELECT
 	lieu.nom_lieu,
 	COUNT(personnage.nom_personnage) AS nombre_habitant
FROM
	lieu
	INNER JOIN personnage ON personnage.id_lieu = lieu.id_lieu
WHERE
	lieu.nom_lieu <> 'Village gaulois' --permet d'exclure !!
GROUP BY 
	lieu.id_lieu
ORDER BY
	nombre_habitant DESC


-- 14. Nom des personnages qui n'ont jamais bu aucune potion. **

-- raisonnement : les id sont des int, si soustrait les id.personnages de potion au id.personnage de personnages, j'obtiendrai l'id du gaulois qui ne bois pas

SELECT
	SUM(personnage.id_personnage) AS somme_personnage,
	SUM(boire.id_personnage) AS somme_boire,
	SUM(personnage.id_personnage) - SUM(boire.id_personnage) AS id_personnage_sobre -- necessité de créer l'alias lors de la soustraction (on ne peut pas soustraire deux alias)
FROM 
	personnage
	INNER JOIN boire ON personnage.id_personnage = boire.id_personnage; -- comparaison marche, mais il n'y a pas de personnage sobre, l'id personnage soble est = 0
    -- essai d'un CASE ELSE mais renvois une erreur

SELECT personnage.id_personnage
FROM personnage
EXCEPT
SELECT boire.id_personnage 
FROM boire -- devrait marcher mais ne marche pas 

SELECT personnage.nom_personnage
FROM personnage
WHERE EXISTS (
    SELECT boire.id_personnage
    FROM boire 
    WHERE personnage.id_personnage <> boire.id_personnage
)--ne marche pas, renvois tous les personnages

-- 15. Nom du / des personnages qui n'ont pas le droit de boire de la potion 'Magique'. **
SELECT
 	GROUP_CONCAT(personnage.nom_personnage)
FROM
	personnage
	INNER JOIN autoriser_boire ON autoriser_boire.id_personnage = personnage.id_personnage
	INNER JOIN potion ON potion.id_potion = autoriser_boire.id_potion
WHERE 
	nom_potion <> 'Magique'
GROUP BY 
	personnage.nom_personnage
LIMIT 3

-- _______________________________________________________________________________
-- En écrivant toujours des requêtes SQL, modifiez la base de données comme suit :
-- A. Ajoutez le personnage suivant : Champdeblix, agriculteur résidant à la ferme Hantassion de Rotomagus.
INSERT INTO personnage (nom_personnage, adresse_personnage, image_personnage, id_lieu, id_specialite)
 VALUES
 ('Champdeblix', 'résidant à la ferme' , 'indisponible.jpg', 6, 12) -- créer, personnage, id_personnage 46

 SELECT
 nom_personnage, adresse_personnage, id_personnage
 FROM personnage
 WHERE personnage.nom_personnage = 'Champdeblix'

-- B. Autorisez Bonemine à boire de la potion magique, elle est jalouse d'Iélosubmarine...
INSERT INTO autoriser_boire (id_personnage, id_potion)
 VALUES
 (12, 1)

 Query 1 ERROR: Duplicate entry '1-12' for key 'PRIMARY' --Bonnemine a deja le droit de boire de la potion magiaue

-- C. Supprimez les casques grecs qui n'ont jamais été pris lors d'une bataille.
DELETE FROM casque
WHERE casque.nom_casque = 'grec'

-- D. Modifiez l'adresse de Zérozérosix : il a été mis en prison à Condate.
UPDATE personnage
SET personnage.adresse_personnage = 'mis en prison'
WHERE personnage.nom_personnage = 'Zérozérosix'

-- E. La potion 'Soupe' ne doit plus contenir de persil.

DELETE FROM composer
WHERE composer.id_potion = 9 AND composer.id_ingredient = 19

-- F. Obélix s'est trompé : ce sont 42 casques Weisenau, et non Ostrogoths, qu'il a pris lors de la bataille 'Attaque de la banque postale'. Corrigez son erreur !

UPDATE prendre_casque
SET prendre_casque.id_casque = 14
WHERE prendre_casque.id_personnage = 5 AND prendre_casque.id_casque = 10

-- _______________________________________________________________________________
-- SELECT
-- lire des données issues de la base de données grâce à la commande SELECT, qui retourne des enregistrements dans un tableau de résultat. Cette commande peut sélectionner une ou plusieurs colonnes d’une table.

-- WHERE
-- La commande WHERE dans une requête SQL permet d’extraire les lignes d’une base de données qui respectent une condition. Cela permet d’obtenir uniquement les informations désirées.

-- LIKE
-- permet d’effectuer une recherche sur un modèle particulier. ( rechercher les enregistrements dont la valeur d’une colonne commence par telle ou telle lettre...)

-- GROUP BY : 
-- La commande GROUP BY est utilisée en SQL pour grouper plusieurs résultats et utiliser une fonction de totaux sur un groupe de résultat. 
-- Sur une table qui contient toutes les ventes d’un magasin : regrouper les ventes par clients identiques / d’obtenir le coût total des achats pour chaque client.

-- ORDER BY
-- La commande ORDER BY permet de trier les lignes dans un résultat d’une requête SQL. Il est possible de trier les données sur une ou plusieurs colonnes, par ordre ascendant ou descendant.

-- COUNT
-- En SQL, la fonction d’agrégation COUNT() permet de compter le nombre d’enregistrement dans une table. 

-- SUM
-- Dans le langage SQL, la fonction d’agrégation SUM() permet de calculer la somme totale d’une colonne contenant des valeurs numériques. 
-- Cette fonction ne fonction que sur des colonnes de types numériques (INT, FLOAT …) et n’additionne pas les valeurs NULL.

-- HAVING
-- similaire à WHERE, mais permet de filtrer en utilisant des fonctions telles que SUM(), COUNT(), AVG(), MIN() ou MAX().

-- IN
-- s’utilise avec la commande WHERE pour vérifier si une colonne est égale à une des valeurs comprise dans set de valeurs déterminés. 
-- Vérifier si une colonne est égale à une valeur OU une autre valeur OU une autre valeur et ainsi de suite, sans avoir à utiliser de multiple fois l’opérateur OR.

-- INNER JOIN
-- lier plusieurs tables entre-elles, retourne les enregistrements lorsqu’il y a au moins une ligne dans chaque colonne qui correspond à la condition

-- DATE_FORMAT
--  permet de formater une donnée DATE dans le format indiqué, directement dans le SQL et pas dans la partie applicative

-- AS (alias)
-- renommer temporairement une colonne ou une table dans une requête.

-- UNION
-- permet de concaténer les résultats de 2 requêtes ou plus. 
-- Pour l’utiliser il est nécessaire que chacune des requêtes à concaténer retournes le même nombre de colonnes, avec les mêmes types de données et dans le même ordre.

-- ANY_VALUE() (usefull for group by, only in MySql)
-- The function return value and type are the same as the return value and type of its argument, but the function result is not checked for the ONLY_FULL_GROUP_BY SQL mode.

-- GROUP_CONCAT() (usefuff for GROUP BY, only in MySQL

-- MIN()/MAX(), 
-- permet de récupérer la 1er ou la dernière ligne concernée

-- LIMIT
-- La clause LIMIT est à utiliser dans une requête SQL pour spécifier le nombre maximum de résultats que l’ont souhaite obtenir. 
-- Cette clause est souvent associé à un OFFSET, c’est-à-dire effectuer un décalage sur le jeu de résultat. 
-- Ces 2 clauses permettent par exemple d’effectuer des système de pagination

--NOT EQUAL TO
-- Pour exclure un enregistrement (ou une ligne) avec un identifiant spécifique d'une table dans une requête SQL, 
-- vous pouvez utiliser la clause WHERE avec l'opérateur NOT EQUAL TO (<>).