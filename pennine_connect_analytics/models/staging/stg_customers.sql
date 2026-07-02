with source as (
        select * from {{ ref('tb_customers_snapshot') }}
),

renamed as (
    select
        customer_id::int                       as customer_id,
        signup_date::date                       as signup_date,
        trim(region)                            as region,
        trim(acquisition_channel)               as acquisition_channel,
        trim(size_band)                         as size_band,
        --since how long customer is part of company
        datediff('day', signup_date, current_date()) as customer_tenure_days,
        dbt_scd_id,
        dbt_updated_at,
        dbt_valid_from,
        dbt_valid_to
    from source
)

select * from renamed