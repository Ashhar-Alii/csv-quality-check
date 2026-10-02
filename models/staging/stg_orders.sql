{{ config(
    materialized='view'
) }}

-- This is the AUDIT point of the Write-Audit-Publish pattern: every test
-- in _staging__models.yml runs against this model before `orders` (the
-- production mart) is allowed to build. If any test fails, dbt build
-- skips `orders` entirely -- the CSV's bad rows never reach production.

with source as (

    select *
    from read_files(
        '{{ var("landing_volume_path") }}',
        format => 'csv',
        header => true,
        inferSchema => true
    )

),

renamed as (

    select
        cast(order_id as string)    as order_id,
        cast(customer_id as string) as customer_id,
        cast(order_date as date)    as order_date,
        cast(amount as double)      as amount,
        cast(status as string)      as status,
        current_timestamp()         as _loaded_at

    from source

)

select * from renamed
