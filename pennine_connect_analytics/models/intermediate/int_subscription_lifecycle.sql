with subscriptions as (
    select * from {{ ref('stg_subscriptions') }}
),

ordered as (
    select
        *,
        --Reason to add product_type is to answer :
        -- did a customer come back to a service they previously walked away from?
        -- If i took only customer then that would be change in decision, if customer changes the product
        -- Exluding product would not be churn recovery 
        lag(status) over (
            partition by customer_id, product_type
            order by go_live_date, subscription_id
        ) as prev_status,
        lag(cancelled_date) over (
            partition by customer_id, product_type
            order by go_live_date, subscription_id
        ) as prev_cancelled_date
    from subscriptions
),

classified as (
    select
        *, 
        case
            --precedence order matters as fraud and doa comes first as they override everything
            --because a fraud and doa cant fall under reactivation  
            when status = 'fraud' then 'fraud'
            when status = 'doa' then 'cancelled_before_go_live'
            --status is active but golive_date is future so pending_activation
            when is_pending_activation_flag then 'pending_activation'
            --If customer has cancelled for same product and again activated then reactivation
            --refer to analysis of customer_id 501 from raw_to_gold_analysis.sql sheet
            when prev_status = 'cancelled'
                 and prev_cancelled_date is not null
                 and go_live_date > prev_cancelled_date
                then 'reactivation'
            when status = 'cancelled' then 'voluntary_cancellation'
            when status = 'active' then 'active'
            else 'unknown'
        end as lifecycle_state
    from ordered
)

select * from classified