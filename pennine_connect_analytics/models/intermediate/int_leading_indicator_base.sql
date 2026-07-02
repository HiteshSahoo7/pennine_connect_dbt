-- Base table for leading-indicator testing: every subscription that went live,
-- with a reference_date to measure signal windows against.
-- churned subs -> reference_date = cancelled_date (the outcome we're predicting)
-- still-active subs -> reference_date = today
-- fraud/doa excluded: they never had a real outcome to test against

with lifecycle as (
    select * from {{ ref('int_subscription_lifecycle') }}
    where lifecycle_state in ('active', 'voluntary_cancellation', 'reactivation')
      and go_live_date is not null
)

select
    subscription_id,
    customer_id,
    lifecycle_state,
    --churn_flag
    lifecycle_state = 'voluntary_cancellation' as is_churned,
    --for churn customer : cancelled_date = reference_date | for active customer : current_date = reference_date 
    coalesce(cancelled_date, current_date()) as reference_date
from lifecycle