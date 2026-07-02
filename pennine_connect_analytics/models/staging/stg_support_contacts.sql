with source as (
    select * from {{ source('pennine_connect', 'TB_SUPPORT_CONTACTS') }}
),
renamed as (
    select
        contact_id::int        as contact_id,
        customer_id::int        as customer_id,
        created_at::timestamp   as created_at,
        trim(channel)            as channel,
        trim(category)           as category,
        resolved_at::timestamp  as resolved_at,
        -- null resolved_at = still open at time of extract, not missing data
        case when resolved_at is null then true else false end as is_unresolved_flag,
        --created resolution hours to solving issue
        datediff('hour', created_at, resolved_at) as resolution_hours
    from source
)
select * from renamed