-- Monthly + annualised voluntary churn rate for the trailing 12 months.

with lifecycle as (
    select * from {{ ref('int_subscription_lifecycle') }}
),

-- trailing 12 month starts, e.g. today=2026-07-01 so data will have 2025-07-01 to 2026-06-01
months as (
    select
        dateadd('month', seq4(), dateadd('month', -12, date_trunc('month', current_date()))) as month_start
    from table(generator(rowcount => 12))
),

-- This cte is denominator to calculate churn percentage 
denom as (
    select
        m.month_start as churn_month,
        count(distinct l.subscription_id) as active_start_of_month
    from months m
    left join lifecycle l
        --added all 3 as denominator
        on l.lifecycle_state in ('active', 'voluntary_cancellation', 'reactivation')
        --this filter is for 2 condition 
        --avoid cross join
        --and excludes subscription that hadn't gone live yet as of corresponding month
        --e.g. golive_date = 2026-03-15 should not count towards jan or feb due to cross join
        and l.go_live_date < m.month_start
        --same way it excludes subscription that was already cancelled as of corresponding month
        --e.g. cancelled_date = 2026-12-01 should not count towards Nov or Dec due to cross join
        and (l.cancelled_date is null or l.cancelled_date >= m.month_start)
    group by 1
),

-- churn events: only voluntary_cancellation counts 
--fraud/doa structurally excluded since lifecycle never tags them that way
churn_events as (
    select
        --which month i am cancelling my subscription
        date_trunc('month', cancelled_date) as churn_month,
        subscription_id,
        --total days spent on that subscription before cancelling
        datediff('day', go_live_date, cancelled_date) as tenure_at_cancel_days
    from lifecycle
    where lifecycle_state = 'voluntary_cancellation'
),

--below CTE is numerator to calculate churn percentage 
numer as (
    select
        churn_month,
        count(distinct subscription_id) as churned_subs,
        -- below is just breakout column only to understand early opt-outs, NOT subtracted from churned_subs above
        count(distinct case when tenure_at_cancel_days <= 30 then subscription_id end)
            as early_life_churned_subs
    from churn_events
    group by 1
)

select
    d.churn_month,
    d.active_start_of_month,
    coalesce(n.churned_subs, 0) as churned_subs,
    coalesce(n.early_life_churned_subs, 0) as early_life_churned_subs,

    -- monthly rate: churned this month / active as of this month's start
    round(coalesce(n.churned_subs, 0)::float
        / nullif(d.active_start_of_month, 0)*100,2) as monthly_churn_rate_pct,

    -- annualised via compounding (1-(1-r)^12), not r*12, 
    -- since the active base shrinks each month as churn happens
    round((1 - power(1 - (coalesce(n.churned_subs, 0)::float
        / nullif(d.active_start_of_month, 0)), 12)) * 100, 2) as annualised_churn_rate_pct

from denom d
left join numer n on d.churn_month = n.churn_month
--to exclude current month July 2026 which has not yet ended
where d.churn_month < date_trunc('month', current_date())
order by 1