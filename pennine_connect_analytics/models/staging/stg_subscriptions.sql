with source as (
    select * from {{ ref('tb_subscriptions_snapshot') }}
),

deduped as (
    -- 32 subscription_ids appear as exact full-row duplicates in source (64 rows).
    -- Keep one instance per subscription_id.
    select *, 
        row_number() over (partition by subscription_id order by subscription_id) as rn
    from source
    qualify rn = 1
),

renamed as (
    select
        subscription_id::int           as subscription_id,
        customer_id::int               as customer_id,
        trim(product_type)             as product_type,
        trim(plan)                     as plan,
        mrr::number(10,2)              as mrr,
        go_live_date::date             as go_live_date,
        trim(status)                   as status,
        cancelled_date::date           as cancelled_date,
        contract_term_months::int      as contract_term_months,

        -- status says active but go_live_date hasn't happened yet as of today
        -- So we are creating below flag rather than removing the rows
        case
            when trim(status) = 'active' and go_live_date::date > current_date()
            then true else false
        end as is_pending_activation_flag,
        dbt_scd_id,
        dbt_updated_at,
        dbt_valid_from,
        dbt_valid_to

    from deduped
)

select * from renamed