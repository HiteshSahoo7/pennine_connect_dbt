-- Tests 6 indicators against churned vs. still-active subscriptions.
-- All signals measured in a fixed 60-day window before reference_date 
-- risk_ratio > 1 = signal elevates churn risk. risk_ratio < 1 = signal is protective.

with base as (
    select * from {{ ref('int_leading_indicator_base') }}
),

-- signal 1: a 'complaint' support contact in the 60 days before reference_date
-- result: no signal (ratio ~0.7-0.8 across windows tested)
complaint_matches as (
    select distinct b.subscription_id
    from base b
    inner join {{ ref('stg_support_contacts') }} s
        on s.customer_id = b.customer_id
        and s.category = 'complaint'
        and s.created_at < b.reference_date
        and s.created_at >= dateadd('day', -60, b.reference_date)
),

-- signal 2: a 'support_ticket_open' portal event in the 60 days before reference_date
-- result: no signal
ticket_open_matches as (
    select distinct b.subscription_id
    from base b
    inner join {{ ref('stg_portal_events') }} p
        on p.customer_id = b.customer_id
        and p.event_type = 'support_ticket_open'
        and p.event_timestamp < b.reference_date
        and p.event_timestamp >= dateadd('day', -60, b.reference_date)
),

-- signal 3: a 'technical_fault' support contact in the 60 days before reference_date
-- result: no signal, actually inverse (~0.3) -- resolved faults may retain customers, not lose them
techfault_matches as (
    select distinct b.subscription_id
    from base b
    inner join {{ ref('stg_support_contacts') }} s
        on s.customer_id = b.customer_id
        and s.category = 'technical_fault'
        and s.created_at < b.reference_date
        and s.created_at >= dateadd('day', -60, b.reference_date)
),

-- signal 4: call_minutes dropped >50% in the trailing 30d vs the prior 30d (usage decline hypothesis)
-- result: no signal at all -- no meaningful usage-decline pattern exists in this data
usage_windows as (
    select
        b.subscription_id,
        sum(case when u.usage_date >= dateadd('day', -30, b.reference_date)
                  and u.usage_date < b.reference_date
                 then u.call_minutes else 0 end) as recent_30d_minutes,
        sum(case when u.usage_date >= dateadd('day', -60, b.reference_date)
                  and u.usage_date < dateadd('day', -30, b.reference_date)
                 then u.call_minutes else 0 end) as prior_30d_minutes
    from base b
    left join {{ ref('stg_usage_daily') }} u on u.subscription_id = b.subscription_id
    group by 1
),
usage_drop_matches as (
    select subscription_id
    from usage_windows
    where prior_30d_minutes > 0
      and (recent_30d_minutes - prior_30d_minutes) / prior_30d_minutes < -0.5
),

-- signal 5: unpaid or part_paid invoice in the 60 days before reference_date
-- result: THE signal -- ratio ~1.69, p=0.075 (moderate confidence, not 95% significant
-- given only 113 churn events total, but the strongest and most defensible candidate found)
billing_matches as (
    select distinct b.subscription_id
    from base b
    inner join {{ ref('stg_billings') }} bill
        on bill.customer_id = b.customer_id
        and bill.status in ('unpaid', 'part_paid')
        and bill.period_month < b.reference_date
        and bill.period_month >= dateadd('day', -60, b.reference_date)
),

-- signal 6: concurrent-call peak in the top decile (>=8, call-days only) in the 60 days before reference_date
-- tested as a capacity-strain risk hypothesis -- result: opposite of hypothesis, ratio ~0.74, p=0.037
-- (statistically the tightest p-value of all 6, but PROTECTIVE not risky -- heavy users are stickier, not strained)
-- call_count > 0 filter excludes the source-system bug where concurrent_peak defaults to 1 on zero-call days
peak_matches as (
    select distinct b.subscription_id
    from base b
    inner join {{ ref('stg_usage_daily') }} u
        on u.subscription_id = b.subscription_id
        and u.usage_date < b.reference_date
        and u.usage_date >= dateadd('day', -60, b.reference_date)
        and u.call_count > 0
        and u.concurrent_peak >= 8
),

-- union all 6 signals into one comparable shape: churned-group counts vs active-group counts
signal_results as (
    select 'support_complaint_60d' as signal_name,
        --counts how many churned subscriptions exist in total (the denominator for the churned group)
        count(distinct case when b.is_churned then b.subscription_id end) as churned_total,
        --had a complaint in their 60-day window before cancelling
        count(distinct case when b.is_churned and m.subscription_id is not null then b.subscription_id end) as churned_with_signal,
        --counts how many still-active subscriptions exist in total (the denominator for the active group).
        count(distinct case when not b.is_churned then b.subscription_id end) as active_total,
        --of those active subscriptions, counts only the ones that also showed up in complaint_matches (had a complaint in their 60-day window before today).
        count(distinct case when not b.is_churned and m.subscription_id is not null then b.subscription_id end) as active_with_signal
    from base b left join complaint_matches m on m.subscription_id = b.subscription_id

    union all

    select 'portal_support_ticket_open_60d',
        count(distinct case when b.is_churned then b.subscription_id end),
        count(distinct case when b.is_churned and m.subscription_id is not null then b.subscription_id end),
        count(distinct case when not b.is_churned then b.subscription_id end),
        count(distinct case when not b.is_churned and m.subscription_id is not null then b.subscription_id end)
    from base b left join ticket_open_matches m on m.subscription_id = b.subscription_id

    union all

    select 'technical_fault_60d',
        count(distinct case when b.is_churned then b.subscription_id end),
        count(distinct case when b.is_churned and m.subscription_id is not null then b.subscription_id end),
        count(distinct case when not b.is_churned then b.subscription_id end),
        count(distinct case when not b.is_churned and m.subscription_id is not null then b.subscription_id end)
    from base b left join techfault_matches m on m.subscription_id = b.subscription_id

    union all

    select 'usage_minutes_drop_50pct_30d',
        count(distinct case when b.is_churned then b.subscription_id end),
        count(distinct case when b.is_churned and m.subscription_id is not null then b.subscription_id end),
        count(distinct case when not b.is_churned then b.subscription_id end),
        count(distinct case when not b.is_churned and m.subscription_id is not null then b.subscription_id end)
    from base b left join usage_drop_matches m on m.subscription_id = b.subscription_id

    union all

    select 'billing_unpaid_or_partpaid_60d',
        count(distinct case when b.is_churned then b.subscription_id end),
        count(distinct case when b.is_churned and m.subscription_id is not null then b.subscription_id end),
        count(distinct case when not b.is_churned then b.subscription_id end),
        count(distinct case when not b.is_churned and m.subscription_id is not null then b.subscription_id end)
    from base b left join billing_matches m on m.subscription_id = b.subscription_id

    union all

    select 'concurrent_peak_top_decile_60d',
        count(distinct case when b.is_churned then b.subscription_id end),
        count(distinct case when b.is_churned and m.subscription_id is not null then b.subscription_id end),
        count(distinct case when not b.is_churned then b.subscription_id end),
        count(distinct case when not b.is_churned and m.subscription_id is not null then b.subscription_id end)
    from base b left join peak_matches m on m.subscription_id = b.subscription_id
)

-- risk_ratio = (churned rate with signal) / (active rate with signal)
select
    signal_name,
    churned_total,
    churned_with_signal,
    round(churned_with_signal::float / nullif(churned_total, 0) * 100, 1) as churned_rate_pct,
    active_total,
    active_with_signal,
    round(active_with_signal::float / nullif(active_total, 0) * 100, 1) as active_rate_pct,
    round((churned_with_signal::float / nullif(churned_total, 0))
        / nullif(active_with_signal::float / nullif(active_total, 0), 0), 2) as risk_ratio
from signal_results
order by risk_ratio desc