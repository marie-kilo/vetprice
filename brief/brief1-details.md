@everyone 
voici une version très guidée du brief, qui vous "impose" les étapes et implique de traiter d'abord un seul site, puis de répliquer la stratégie sur les autres


## Partie A : un seul site, de bout en bout

## Partie A : un seul site

### A1. Profiler un relevé

Chargez **un** relevé du site dans un notebook. Mesurez et consignez :

- nombre de lignes, et nombre de lignes à `ean` nul ou vide ;
- nombre de doublons d'`ean` dans le relevé (un produit peut revenir sous plusieurs conditionnements) ;
- liste des colonnes présentes.

Ces valeurs servent de justification chiffrée en A2 et en `DECISIONS.md`.

### A2. Poser le modèle

Écrivez un `schema.sql` séparant deux entités :

- le **produit** : attributs stables (nom, marque, `ean`) ;
- le **relevé** : mesure datée (prix, disponibilité, date, site).

Clé produit imposée : `cle = ean` si `ean` est non nul et non vide, sinon `cle = url`. Aucune autre stratégie de repli. `DECISIONS.md` reporte le taux de lignes sans `ean` mesuré en A1 comme justification.

### A3. Charger les relevés du site

Chargez au moins deux dates du site (trois si disponibles). Deux contraintes :

- **rejouable** : recharger le même relevé ne duplique rien et ne lève aucune erreur ;
- **dédoublonnage avant insertion** : les doublons internes du relevé sont retirés avant l'`INSERT`, pas après.

Implémentation du dédoublonnage : la colonne de `drop_duplicates` dépend du périmètre du dataframe.

- dataframe = un seul dossier horodaté (un relevé) : `df.drop_duplicates(["cle"])` ;
- dataframe = tous les dossiers horodatés d'un site (plusieurs dates) : `df.drop_duplicates(["cle", "scraped_at"])`.

Justification : dans un relevé unique, deux lignes de même `cle` sont un doublon interne à retirer. Sur plusieurs dates, deux lignes de même `cle` mais de `scraped_at` distinct sont deux versions à conserver, pas un doublon. Dédoublonner sur `cle` seule un dataframe multi-dates écrase l'historique.

Implémentation de la rejouabilité : `TRUNCATE` de la table de relevé courant avant chaque chargement.

### A4. Historiser en SQL

Implémentez un historique SCD2 sur le produit avec trois colonnes : `valid_from`, `valid_to`, `is_current`.

> `is_current` : booléen vrai sur exactement une ligne par produit, sa version courante. Les versions closes l'ont à faux.

Logique, en SQL pur, à l'arrivée d'un nouveau relevé pour un produit connu dont un attribut suivi a changé :

1. fermer l'ancienne ligne courante : `valid_to` = date du nouveau relevé, `is_current` = faux ;
2. ouvrir une nouvelle ligne : `valid_from` = date du nouveau relevé, `is_current` = vrai.

Attributs suivis : `price`, `in_stock`. Appliquez la logique aux relevés dans l'ordre chronologique.

Sortie exigée en fin d'étape, sur le site : **valeur d'un produit à une date donnée**. Vérification sur un produit dont le prix a changé entre deux relevés, identifié à l'œil.

### A5. Surveiller le site

À partir de l'historique de A4, produisez un rapport (vue SQL ou script Python, forme libre) répondant à :

- produits dont le prix a changé entre les deux derniers relevés, écart en euros et en pourcentage ;
- produits apparus et produits disparus ;
- taux de produits sans `ean` exploitable, comme indicateur de qualité de la source.

Fin de partie A : pipeline complet et vérifié sur un site.
