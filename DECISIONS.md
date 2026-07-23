# Décisions de modélisation — Brief Historisation VetPrice

## 1. Analyse du format des relevés

J’ai analysé les colonnes présentes dans tous les relevés de tous les sites.  
Les résultats montrent que :

### Sites au format stable
- animalis  
- clubvetshop  
- univers_veto  
- vetostore  

Ces sites conservent les mêmes colonnes entre avril et juillet.

### Sites au format instable
- bitiba_fr  
- chronovet  
- pharmacy4pets  
- vetoplus  
- zooplus_fr  

Ces sites ajoutent, retirent ou modifient des colonnes entre les relevés d’avril et ceux de juillet.

### Site au format très pauvre
- maxizoo  

Ce site fournit très peu d’informations (pas de prix, pas de stock, peu de métadonnées).

### Sites au format très riche (avril uniquement)
- bitiba_fr (2026‑04‑01)  
- zooplus_fr (2026‑04‑01)  

Ces relevés contiennent beaucoup de colonnes (prix barré, prix au kilo, texte de stock, etc.), qui disparaissent dans les relevés de juillet.

### Cas particulier : chronovet
Le site chronovet a changé de format entre avril et juillet :
- Avril : 14 colonnes  
- Juillet : 19 colonnes  
Colonnes ajoutées : `description_short`, `species`, `price_was`, `conditioning`, `weight_kg`.

Je décide d’intégrer ces colonnes dans la dimension produit, en acceptant des valeurs NULL pour les relevés antérieurs.

---

## 2. Fiabilité du champ EAN

Sur l’ensemble des relevés (388 784 produits), j’ai mesuré :

- 360 862 valeurs EAN non nulles  
- 27 922 valeurs EAN manquantes ou vides  
→ **7.18 % de produits sans EAN**

L’EAN est donc un identifiant **majoritairement fiable**, mais **pas universel**.  
Certains sites ne fournissent jamais d’EAN (ex : maxizoo), et d’autres ont des EAN incohérents.

### Doublons EAN
J’ai mesuré que **23.68 %** des produits ont un EAN apparaissant plus d’une fois.  
Un même EAN peut correspondre à :
- plusieurs dates de relevé,  
- plusieurs sites marchands,  
- plusieurs conditionnements ou variantes.

L’EAN identifie le produit, mais **pas la ligne de relevé**.

---

## 3. Décision : clé produit

### 3.1. Quand l’EAN est présent
J’utilise l’EAN comme identifiant naturel du produit.

### 3.2. Quand l’EAN est absent
Je n’ai pas rejeté les lignes sans EAN (cela ferait perdre 7.18 % des produits).  
J’ai défini une **clé de repli** basée sur :

- `site` : distingue les catalogues entre marchands  
- `sku` : identifiant interne du site, présent dans ~95 % des produits  
- `name` normalisé : présent dans 100 % des produits, stabilisé (minuscules, accents retirés)

Cette combinaison minimise les faux doublons et garantit une identification robuste des produits dépourvus d’EAN.

---

## 4. Décisions de modélisation

### 4.1. Modèle flexible
J’autorise les colonnes NULL dans la dimension produit et dans les relevés, car les formats varient fortement entre sites.

### 4.2. Colonnes stables dans la dimension produit
J’intègre les colonnes présentes dans la majorité des sites :

- site  
- url  
- scraped_at  
- ean  
- sku  
- name  
- brand  
- category  
- price  
- currency  
- in_stock  
- image_url  
- extra  

### 4.3. Colonnes variables
Les colonnes spécifiques à certains sites sont intégrées dans `extra` ou en colonnes optionnelles :  
`description_short`, `species`, `price_was`, `conditioning`, `weight_kg`,  
`rating`, `review_count`, `stock_text`, `atc_code`, etc.

### 4.4. Historisation
Je n’historise que les colonnes essentielles :
- `price`  
- `in_stock`

Les autres colonnes ne sont pas historisées dans le SCD2.

