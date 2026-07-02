with source as (
    select * from {{ source('pennine_connect', 'TB_PORTAL_EVENTS') }}
),
renamed as (
    select
        event_id::int             as event_id,
        customer_id::int            as customer_id,   -- null on 1640/4810 34% of rows, kept not dropped
        trim(event_type)             as event_type,
        event_timestamp::timestamp   as event_timestamp,
        --below flag is to identify customer_id is null 
        case when customer_id is null then true else false end as is_unattributed_flag
    from source
)
select * from renamed