-- ============================
-- TABLE PRODUIT (dimension)
-- ============================


CREATE TABLE product (
    product_id      SERIAL PRIMARY KEY,

    -- cle = ean si présent, sinon cle = url
    cle             TEXT NOT NULL UNIQUE,

    -- Attributs stables
    ean             TEXT,
    name            TEXT NOT NULL,
    brand           TEXT,
    category        TEXT,
    description_short TEXT,
    variant_name    TEXT,
    pack_size       TEXT,
    species         TEXT,
    conditioning    TEXT,
    weight_kg       NUMERIC,
    mpn             TEXT,
    atc_code        TEXT,
    image_url       TEXT,
    extra           JSONB
);


-- ============================
-- TABLE RELEVÉ (faits)
-- ============================

CREATE TABLE price_fact (
    price_fact_id       SERIAL PRIMARY KEY,
    product_id          INTEGER NOT NULL REFERENCES product(product_id),

    -- Contexte du relevé
    cle                 TEXT NOT NULL,
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

    extra               JSONB,

    -- Contrainte :
    -- un relevé est unique par (cle, site, scraped_at)
    CONSTRAINT uq_price_fact UNIQUE (cle, site, scraped_at)
);


CREATE TABLE produit_historise
(
    site       TEXT,
    cle        TEXT,
    ean        TEXT,
    url        TEXT,
    name       TEXT,
    brand      TEXT,
    price      NUMERIC,
    in_stock   BOOLEAN,
    valid_from DATE,
    valid_to   DATE,
    is_current BOOLEAN,
    PRIMARY KEY (site, cle, valid_from)
);
