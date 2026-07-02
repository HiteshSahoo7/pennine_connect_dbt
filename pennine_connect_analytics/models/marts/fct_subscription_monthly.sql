with lifecycle as (
    select * from {{ ref('int_subscription_lifecycle') }}
    --Only below 3 status needed for churn analysis
    where lifecycle_state in ('active', 'voluntary_cancellation', 'reactivation')
      and go_live_date is not null
),

--Below CTE is used to calculate start_month and end_month/current_month of customer's subscription
month_bounds as (
    select
        subscription_id,
        customer_id,
        product_type,
        plan,
        mrr,
        lifecycle_state,
        contract_term_months,
        date_trunc('month', go_live_date) as start_month,
        coalesce(
            date_trunc('month', cancelled_date),
            date_trunc('month', current_date())
        ) as end_month
    from lifecycle
),
-- Below CTE to create a continuous monthly calendar spine for one row per month 
-- between the golive_date and cancelled_date/ currentdate(for active)
month_spine as (
    select
        dateadd('month', seq4(), (select min(start_month) from month_bounds)) as activity_month
    from table(generator(rowcount => 1000))
    qualify activity_month <= (select max(end_month) from month_bounds)
),
--Below CTE is used to explode/flatten from golive_month to cancelled_month/current_date
exploded as (
    select
        b.subscription_id,
        b.customer_id,
        b.product_type,
        b.plan,
        b.contract_term_months,
        b.lifecycle_state,
        m.activity_month,
        b.mrr
    from month_bounds b
    inner join month_spine m
        on m.activity_month between b.start_month and b.end_month
)

select * from exploded
order by subscription_id, activity_month