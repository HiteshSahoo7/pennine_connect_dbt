with source as (
    select * from {{ source('pennine_connect', 'TB_USAGE_DAILY') }}
),
renamed as (
    select
        subscription_id::int    as subscription_id,
        usage_date::date         as usage_date,
        call_count::int          as call_count,
        call_minutes::number(10,2) as call_minutes,
        concurrent_peak::int     as concurrent_peak
    from source
)
select * from renamed