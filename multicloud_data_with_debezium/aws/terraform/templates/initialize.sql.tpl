CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS ${table_name} (
    id uuid DEFAULT uuid_generate_v4 (),
    sku char(15) not null,
    name varchar(150) not null,
    description text,
    price double precision not null default 0,
    available integer
);