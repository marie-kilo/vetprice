-- ============================
-- TABLE PRODUIT (dimension)
-- ============================

CREATE TABLE product (
    product_id          SERIAL PRIMARY KEY,

    -- Identifiant naturel (peut être NULL)
    ean                 TEXT,

    -- Clé de repli pour les produits sans EAN
    site                TEXT NOT NULL,
    sku                 TEXT,
    name_normalized     TEXT NOT NULL,

    -- Attributs stables
    name                TEXT NOT NULL,
    brand               TEXT,
    category            TEXT,
    description_short   TEXT,
    variant_name        TEXT,
    pack_size           TEXT,
    species             TEXT,
    conditioning        TEXT,
    weight_kg           NUMERIC,
    mpn                 TEXT,
    atc_code            TEXT,

    -- Métadonnées diverses
    image_url           TEXT,
    extra               JSONB,

    -- Contrainte : EAN unique quand il est présent
    CONSTRAINT uq_product_ean UNIQUE (ean),

    -- Contrainte : clé de repli unique pour les produits sans EAN
    CONSTRAINT uq_product_fallback UNIQUE (site, sku, name_normalized)
);

-- ============================
-- TABLE RELEVÉ (faits)
-- ============================

CREATE TABLE price_fact (
    price_fact_id       SERIAL PRIMARY KEY,
    product_id          INTEGER NOT NULL REFERENCES product(product_id),

    -- Contexte du relevé
    site                TEXT NOT NULL,
    url                 TEXT NOT NULL,
    scraped_at          TIMESTAMPTZ NOT NULL,

    -- Mesures
    price               NUMERIC,
    price_was           NUMERIC,
    currency            TEXT NOT NULL,
    in_stock            BOOLEAN,
    stock_text          TEXT,
    price_per_unit      NUMERIC,
    price_per_unit_label TEXT,
    rating              NUMERIC,
    review_count        INTEGER,

    -- Métadonnées
    extra               JSONB
);


-- =========================
-- Justification de la clé de repli
-- =========================
-- 1) Je ne rejete pas les lignes sans EAN : cela ferait perdre ~7.18 % des produits.
-- 2) EAN n'est pas unique (~23.68 % de doublons) : il ne peut pas être clé primaire.
-- 3) J'utilise une clé de repli (site, sku, name_normalized) car :
--    - site distingue les catalogues entre marchands,
--    - sku est l'identifiant interne du site (présent dans ~95 % des lignes),
--    - name_normalized est présent partout et stabilisé (minuscules, accents retirés).
-- 4) Cette combinaison minimise les faux doublons tout en conservant les produits sans EAN.
