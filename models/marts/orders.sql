{{ config(
    materialized='incremental',
    unique_key='order_id',
    incremental_strategy='merge',
    file_format='delta'
) }}

-- This is the PUBLISH step. It refs() stg_orders, so dbt's DAG makes it
-- depend on every test defined on stg_orders -- if one of those tests
-- fails, dbt build marks this model SKIPPED and the merge never runs.
-- Whatever was last successfully published stays exactly as it was.

select
    order_id,
    customer_id,
    order_date,
    amount,
    status,
    _loaded_at
from {{ ref('stg_orders') }}

{% if is_incremental() %}
where _loaded_at > (select coalesce(max(_loaded_at), timestamp('1900-01-01')) from {{ this }})
{% endif %}
