# Brief 01 : historiser des relevés de prix

> Objectif : construire une base historisée à partir de relevés déjà collectés.

> Compétences visées (RNCP-37638) : **C13, niveau 2** (modéliser une structure d'entrepôt), **C17, niveau 3** (implémenter des variations dans les dimensions, en autonomie et en le justifiant sur un cas nouveau), **C10** et **C9, niveau 2-3**.

## Contexte

Un formateur qui fait tourner des scrapers depuis avril vous confie des données scrapées : 
- plusieurs sites marchands vétérinaires
- plusieurs dates de relevé
- un format commun

🔴 Important :

- Ce brief ne porte pas sur la collecte ! (*ce sera l'objet d'un autre brief*)
- Et donc les données sont fournies telles quelles.


On veut transformer ces relevés en une base capable de répondre à trois questions qu'aucun relevé pris isolément ne permet de poser :

- Qu'est-ce qui a changé entre deux relevés ?
- Qu'est-ce qui n'existait pas avant, ou qui a disparu ?
- Que valait tel produit à une date donnée ?

🟢 On veut donc un entrepôt historisé : 
- On ne remplace pas les données précédentes
- On garde les données ainsi que la trace de "ce qui était vrai à quel moment" (i.e. un peu comme `git`).

## 0. Les données reçues

Un fichier par site et par date de relevé, une ligne JSON par produit :

```json
{
  "site": "chronovet",
  "url": "https://www.chronovet.fr/...",
  "scraped_at": "2026-07-18T14:18:58+00:00",
  "ean": "3597134012025",
  "sku": "PRE111",
  "name": "Virbac Care Prevexto - collier antiparasitaire pour chien",
  "brand": "VIRBAC",
  "price": 29.62,
  "currency": "EUR",
  "in_stock": true,
  "extra": {}
}
```

Le champ `ean` est le candidat naturel de clé (code-barres du produit, identifiant théoriquement stable) 
Théoriquement seulement, parce que sa fiabilité dépend du site (+ quelques petites exceptions).

## 1. Profilage et modélisation

Avant de charger quoi que ce soit en base : chargez un relevé dans un notebook. 
Comptez et notez au moins :

- le nombre de lignes, et le nombre de valeurs `ean` manquantes ou vides ;
- le nombre de doublons d'`ean` au sein d'un même relevé (un même produit peut apparaître plusieurs fois selon le conditionnement) ;
- les colonnes présentes, et si elles sont identiques d'un relevé à l'autre pour votre site (elles ne le sont pas forcément : un site peut avoir été mis à jour).

Sur cette base, posez un MLD (Modèle Logique des Données, on se contentera d'un `schema.sql`) qui distinguent explicitement :

- le **produit** : ce qui devrait rester stable (nom, marque, EAN) ;
- le **relevé** : une mesure datée (prix, disponibilité, à quelle date, sur quel site).

🟡 Un point à trancher avant de coder : que faire d'une ligne sans `ean` ? 

- la rejeter perd de l'information 
- inventer une clé de repli (marque et nom normalisés, par exemple) en récupère au prix d'un risque de faux doublons
- vous pouvez imaginer une autre solution, mais vous devez la justifier


## 2. Chargement des relevés fournis

- Chargez au moins deux dates de relevé de votre site (trois si vous en avez trois). 
- Le chargement doit être **rejouable** : relancer sur le même relevé ne doit ni dupliquer, ni échouer.

💫 Un même relevé peut contenir des doublons internes (même produit, plusieurs déclinaisons) : dédoublonnez avant l'insertion, pas après.

## 3. Historiser à la main (SQL)

Sur votre dimension produit (ou directement sur les relevés si le produit ne varie pas chez votre site, seul le prix bouge), implémentez une historisation de type SCD2 : `valid_from`, `valid_to`, un indicateur de ligne courante. 

> indicateur de ligne courante = une colonne booléenne (souvent nommée `is_current` ou `current_flag`) qui vaut vrai sur exactement une ligne par entité : celle qui représente l'état présent. Toutes les autres lignes de cette même entité (les versions historiques, closes) l'ont à faux.

Écrivez la logique en SQL pur : quand un nouveau relevé arrive pour un produit déjà connu, si un attribut suivi a changé, l'ancienne ligne se ferme (`valid_to` renseigné) et une nouvelle s'ouvre. Testez sur vos deux ou trois relevés réels.

Requête à faire fonctionner à la fin de cette étape, sur votre propre cas : **quel était le prix (ou l'état) de tel produit à telle date ?**

## 4. Historiser avec dbt snapshot

Reprenez le même besoin, avec l'outil vu lundi. Un [snapshot dbt](https://docs.getdbt.com/docs/build/snapshots) fait exactement ce que vous venez d'écrire à la main : détecter le changement, fermer l'ancienne version, ouvrir la nouvelle.

Note : dbt snapshot ajoute automatiquement `dbt_valid_from` et `dbt_valid_to`, et la convention est `dbt_valid_to` IS NULL pour la ligne courante, sans booléen séparé par défaut. Si vos deux implémentations (SQL manuel avec un booléen explicite, snapshot dbt sans) doivent produire « le même historique », il faut soit ajouter ce booléen après coup sur la table snapshot,
soit accepter que l'équivalence se vérifie sur valid_from/valid_to seuls et pas sur la présence du booléen lui-même. 

- déclarez vos relevés comme `source()` (comme au brief dbt de la mégabase) ;
- écrivez un `snapshot` avec une stratégie `check` sur les colonnes qui vous intéressent (`price`, `in_stock`...) ;
- lancez `dbt snapshot` sur vos deux ou trois relevés successifs (un run dbt = un relevé traité) ;
- comparez le résultat à ce que vous avez obtenu à la main en SQL : mêmes lignes, mêmes dates de validité.

🔴 Si vos deux implémentations divergent : c'est le signe que la stratégie `check` ne surveille pas exactement les mêmes colonnes que votre logique manuelle, ou que le grain n'est pas le même des deux côtés.

> 🟢 Rappel : le **grain** d'une table, c'est ce qu'une seule ligne représente. La question s'est déjà posée dans les briefs précédents (l'entrepôt, analyses_etoile.sql) : une ligne, c'est un produit ? Un produit à une date donnée ? Une observation brute, changement ou pas ?

🟢 Note : Ici, deux grains sont possibles pour l'historique d'un produit, et ils ne donnent pas le même nombre de lignes sur les mêmes données.

- Option 1 : grain = un changement de valeur (le SCD2 classique) : une nouvelle ligne s'ouvre uniquement quand price (ou l'attribut suivi) change réellement. Si le prix reste identique entre deux relevés, valid_to de la ligne existante s'étend, aucune ligne n'est créée. 
- Option 2 : grain = un relevé : chaque passage produit une nouvelle ligne, que la valeur ait bougé ou non.

## 5. Surveiller

**Implémentez une vue SQL ou un script python** (ou autre, aucune limite de forme), à partir de l'historique construit aux étapes 3 et 4 pour pouvoir répondre à :

- quels produits ont changé de prix entre les deux derniers relevés, et de combien (en valeur et en pourcentage) ;
- quels produits sont apparus, quels produits ont disparu (rupture, retrait) ;
- quel pourcentage de vos produits n'a pas d'EAN exploitable, comme indicateur de qualité de la source elle-même.


## Bonus

- Exportez votre historique en Parquet et requêtez-le en duckdb : `SELECT * FROM 'export_*.parquet'`, comparez le temps de réponse à PostgreSQL sur la même question.
- Si votre relevé contient un prix barré ou un prix de référence, en plus du prix courant, intégrez-le à votre modèle : c'est une deuxième mesure, pas un doublon de la première.



## Livrables

| Livrable | Forme |
|---|---|
| Le schéma (produit, relevé, dimension historisée) | MCD, MLD, `schema.sql` |
| Le chargement des relevés fournis, rejouable | script ou notebook |
| L'historisation en SQL pur | fichier `.sql`, requête « valeur à la date D » incluse |
| Le snapshot dbt équivalent | projet dbt, `dbt snapshot` exécutable |
| Le rapport de surveillance | requête ou script, sortie lisible |
| Les arbitrages | `DECISIONS.md` : clé de repli si EAN absent, colonnes suivies par le snapshot, point RGPD |

## Indicateurs de performance

- le chargement d'un même relevé deux fois de suite ne duplique rien ;
- la requête « valeur à la date D » répond correctement, vérifiée sur au moins un produit dont vous connaissez l'historique à l'oeil ;
- l'implémentation SQL manuelle et le snapshot dbt produisent le même historique sur les mêmes données (vérifier avec `pandas` :) ;
- le rapport de surveillance tient en une exécution et produit un résultat non trivial (au moins une variation réelle détectée) ;
- `DECISIONS.md` justifie la stratégie de repli EAN par un chiffre mesuré, pas par une supposition.

## Modalités

- Travail individuel.
- Prérequis : le brief dbt de la mégabase (le squelette et `source()` vous sont déjà familiers), le brief SQL avancé (le raisonnement trigger contre reconstruction prépare directement la question SCD2 manuel contre snapshot).
- Base locale, PostgreSQL suffit ; aucun déploiement Scalingo n'est demandé pour ce brief.
- Durée indicative : un jour et demi.
