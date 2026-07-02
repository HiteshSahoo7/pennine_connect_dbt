with source as (
    select * from {{ source('pennine_connect', 'TB_BILLINGS') }}
),
renamed as (
    select
        invoice_id::int          as invoice_id,
        customer_id::int          as customer_id,
        period_month::date        as period_month,
        amount_due::number(10,2)  as amount_due,
        amount_paid::number(10,2) as amount_paid,
        trim(status)               as status
    from source
)
select * from renamed