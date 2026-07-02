CREATE OR REPLACE DATABASE PENNINE_CONNECT_RAW_DEV;
CREATE OR REPLACE DATABASE PENNINE_CONNECT_CURATED_DEV;
CREATE OR REPLACE DATABASE PENNINE_CONNECT_ANALYTICS_DEV;

CREATE OR REPLACE SCHEMA PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA; 

--------------------------------RAW TABLES

SELECT COUNT(*) FROM  PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_CUSTOMERS; --700
SELECT COUNT(*) FROM  PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_BILLINGS; --14089
SELECT COUNT(*) FROM  PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_PORTAL_EVENTS; --4810
SELECT COUNT(*) FROM  PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_SUBSCRIPTIONS; --838
SELECT COUNT(*) FROM  PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_SUPPORT_CONTACTS; --1280
SELECT COUNT(*) FROM  PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_USAGE_DAILY; --180990


SELECT * FROM  PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_CUSTOMERS LIMIT 50;
SELECT * FROM  PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_BILLINGS LIMIT 50;
SELECT * FROM  PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_PORTAL_EVENTS LIMIT 50;
SELECT * FROM  PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_SUBSCRIPTIONS LIMIT 50;
SELECT * FROM  PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_SUPPORT_CONTACTS LIMIT 50;
SELECT * FROM  PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_USAGE_DAILY LIMIT 50;

-----------------------------RBAC----------------------------------------------------
--RAW 
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE SVC_DBT_ROLE;

GRANT USAGE ON DATABASE PENNINE_CONNECT_RAW_DEV TO ROLE SVC_DBT_ROLE;

GRANT USAGE ON SCHEMA PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA TO ROLE SVC_DBT_ROLE;

GRANT SELECT ON ALL TABLES
IN SCHEMA PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA
TO ROLE SVC_DBT_ROLE;

GRANT SELECT ON FUTURE TABLES
IN SCHEMA PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA
TO ROLE SVC_DBT_ROLE;

--CURATED 
GRANT USAGE ON DATABASE PENNINE_CONNECT_CURATED_DEV
TO ROLE SVC_DBT_ROLE;

GRANT CREATE SCHEMA
ON DATABASE PENNINE_CONNECT_CURATED_DEV
TO ROLE SVC_DBT_ROLE;

GRANT USAGE ON ALL SCHEMAS
IN DATABASE PENNINE_CONNECT_CURATED_DEV
TO ROLE SVC_DBT_ROLE;

GRANT CREATE TABLE ON ALL SCHEMAS
IN DATABASE PENNINE_CONNECT_CURATED_DEV
TO ROLE SVC_DBT_ROLE;

GRANT CREATE VIEW ON ALL SCHEMAS
IN DATABASE PENNINE_CONNECT_CURATED_DEV
TO ROLE SVC_DBT_ROLE;

GRANT CREATE TABLE ON FUTURE SCHEMAS
IN DATABASE PENNINE_CONNECT_CURATED_DEV
TO ROLE SVC_DBT_ROLE;

GRANT CREATE VIEW ON FUTURE SCHEMAS
IN DATABASE PENNINE_CONNECT_CURATED_DEV
TO ROLE SVC_DBT_ROLE;


-----------------------------CUSTOMER SNAPSHOT for Change data capture in dbt----------------------------
SELECT * FROM PENNINE_CONNECT_CURATED_DEV.SNAPSHOTS.TB_CUSTOMERS_SNAPSHOT LIMIT 10;

-----------------------------CUSTOMER ANALYSIS-------------------------------------------------

--UNIQUE ID CHECK : PASS
SELECT DISTINCT CUSTOMER_ID FROM PENNINE_CONNECT_CURATED_DEV.SNAPSHOTS.TB_CUSTOMERS_SNAPSHOT
ORDER BY 1;

--CHECK CUSTOMER SIGNUP SPIKE FOR ANY DAY : NOTHING FOUND
SELECT SIGNUP_DATE, COUNT(CUSTOMER_ID) FROM PENNINE_CONNECT_CURATED_DEV.SNAPSHOTS.TB_CUSTOMERS_SNAPSHOT 
GROUP BY 1
ORDER BY 2 DESC;

--CHECK CUSTOMER SIGNUP SPIKE FOR ANY MONTH : NOTHING FOUND
--JUNE AND SEPTEMBER is lowest 46 whereas MAR is highest with 80
SELECT MONTH(SIGNUP_DATE), COUNT(CUSTOMER_ID) FROM PENNINE_CONNECT_CURATED_DEV.SNAPSHOTS.TB_CUSTOMERS_SNAPSHOT 
GROUP BY 1
ORDER BY 2 DESC;

--Check Customer's signup trends 
SELECT CONCAT(YEAR(SIGNUP_DATE),'-',LPAD(MONTH(SIGNUP_DATE),2,'0')) AS YEARMONTH, COUNT(CUSTOMER_ID) FROM PENNINE_CONNECT_CURATED_DEV.SNAPSHOTS.TB_CUSTOMERS_SNAPSHOT 
GROUP BY 1
ORDER BY 1 ASC;
--There's a drastic fall from 2023-01 to 2023-02 i.e. 21 -> 12 
--2023-10 to 2023-11 15 -> 6 single digit
--2023-11 to 2023-12 from 6 -> 16 Amazing we did great during chirstmas holiday time
--2024-02 to 2024-03 from 13 -> 26 Amazing result due FY end may be 
--2023-10 to 2023-11 unlike last year we did great, as there was no fall in counts 15 -> 14
--But 2023-11 to 2023-12 Unlike last year was not that amazing just 14 -> 17
--Also 2025-02 to 2025-03 unlike last year we cound not double the count during FY ends 16 -> 20
--And whenever FY ends we are seeing dip 2024-03 to 04 26->19 and 2025-03 to 04 20->13
--Unlike previous year we did some mistake during this holiday as 2025-11 to 12 20->14
--But we fixed FY 202603-04 16->19, but still could not hold as next month 05 went down 19->11
--Also add since how long customer is part of data in dbt


--Check customer's region penetrations : Nothing Found 
select region, count(customer_id) as count from 
PENNINE_CONNECT_CURATED_DEV.SNAPSHOTS.TB_CUSTOMERS_SNAPSHOT 
group by 1
order by 2 desc;

---------------------------------------SUBSCRIPTION ANALYSIS-----------------------------------------
select * from PENNINE_CONNECT_CURATED_DEV.SNAPSHOTS.TB_SUBSCRIPTIONS_SNAPSHOT limit 10;

select count(*) from PENNINE_CONNECT_CURATED_DEV.SNAPSHOTS.TB_SUBSCRIPTIONS_SNAPSHOT; --838

select distinct * from PENNINE_CONNECT_CURATED_DEV.SNAPSHOTS.TB_SUBSCRIPTIONS_SNAPSHOT; --806 
--32 Rows are duplicates 

select * , count(*) as cnt
from PENNINE_CONNECT_CURATED_DEV.SNAPSHOTS.TB_SUBSCRIPTIONS_SNAPSHOT
group by all 
having cnt > 1;
--These are 32 rows that are duplicated | need to dedup in dbt 
--#If i dont dedup then i would be calculating MRR twice 


--Check subscription ID as pk key if null  : No Nulls | Looks Good
select * from PENNINE_CONNECT_CURATED_DEV.SNAPSHOTS.TB_SUBSCRIPTIONS_SNAPSHOT where subscription_id is null;

--Check Customer ID as foreign key if null  : No Nulls | Looks Good 
select * from PENNINE_CONNECT_CURATED_DEV.SNAPSHOTS.TB_SUBSCRIPTIONS_SNAPSHOT where customer_id is null;

--Check Status : No null values | 4 values | Looks good  
select distinct status
from PENNINE_CONNECT_CURATED_DEV.SNAPSHOTS.TB_SUBSCRIPTIONS_SNAPSHOT;

--Check Product Type : No nulls 3 values | Looks Good
select distinct product_type
from PENNINE_CONNECT_CURATED_DEV.SNAPSHOTS.TB_SUBSCRIPTIONS_SNAPSHOT;

--Check Plan : No nulls 8 values | Looks Good
select distinct plan
from PENNINE_CONNECT_CURATED_DEV.SNAPSHOTS.TB_SUBSCRIPTIONS_SNAPSHOT;

--check NULL for DOA subscriptions as per readme | PASS all rows having null as go live date 
select status, go_live_date
from PENNINE_CONNECT_CURATED_DEV.SNAPSHOTS.TB_SUBSCRIPTIONS_SNAPSHOT
where status = 'doa';

--Check doa and canelled date | 
select status, cancelled_date, *
from PENNINE_CONNECT_CURATED_DEV.SNAPSHOTS.TB_SUBSCRIPTIONS_SNAPSHOT
where status = 'doa'
order by 2 desc;
--#How come cancelled date is in future 


--check Cancelled date NULL while active as per readme | PASS as all 665 rows are null for active 
select status, cancelled_date
from PENNINE_CONNECT_CURATED_DEV.SNAPSHOTS.TB_SUBSCRIPTIONS_SNAPSHOT
where status = 'active';

----check golive date for active members| No Nulls
select status, go_live_date
from PENNINE_CONNECT_CURATED_DEV.SNAPSHOTS.TB_SUBSCRIPTIONS_SNAPSHOT
where status = 'active'
order by 2 desc;

select *
from PENNINE_CONNECT_CURATED_DEV.SNAPSHOTS.TB_SUBSCRIPTIONS_SNAPSHOT
where 1=1
and status = 'active'
and go_live_date > current_date()
order by 2 desc;
--#Around 10 subscription are active but not yet gone live | So MRR should not be considered 




/*
Subscription Summary
1. 32 rows are duplicated | Need to dedup else MRR will spike
2. For Subscription 100067 with Customer 57 status is doa but Cancelled Date is in future i.e. 2026-07-20 | Need to check 
3. 10 Active customers having go live date as future, so they are yet to go live, so no need to calculate MRR that will spike
*/

-------------------------------------BILLINGS ANALYSIS--------------------------------
SELECT * FROM PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_BILLINGS LIMIT 10;
SELECT COUNT(*) FROM PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_BILLINGS; --14089

SELECT DISTINCT * FROM PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_BILLINGS; --14089 NO DUPLICATES

--check null customer id as foreign key | No Null | Looks Good
select * from PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_BILLINGS; where customer_id is null;

--check date range for period month  | Range from 2022-09-01 to 2026-06-01 | Looks good 
select min(period_month) , max(period_month)
from PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_BILLINGS;

--check nulls for period month  | no nulls | Looks good 
select * 
from PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_BILLINGS where period_month is null;

--check amount due and amount paid range if negative | No Negatives | Looks good
select min(amount_due) , max(amount_due), min(amount_paid), max(amount_paid)
from PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_BILLINGS;

--check if amount paid exceeds amount due | Zero Row | Looks Good 
select * from PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_BILLINGS
where  amount_paid > amount_due;

--check status distinct | 3 distinct | Looks good 
select distinct status from PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_BILLINGS;

--check status distribution | very less unpaid 294 out of paid 12749 and part paid 1046 | Looks good 
select status, count(*) as cnt 
from PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_BILLINGS
group by 1;

--check if amount mismatch when status is paid | No records | Looks Good 
select *
from PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_BILLINGS
where 1=1
and status = 'paid'
and amount_due <> amount_paid; 

--check amount paid should be zero when status = unpaid | No records | Looks Good 
select *
from PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_BILLINGS
where 1=1
and status = 'unpaid'
and amount_paid <> 0; 

--check amount paid should not be zero and amount due and paid should not equal when status = part_paid | No records | Looks Good 
select *
from PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_BILLINGS
where 1=1
and status = 'part_paid'
and (amount_paid = 0 or amount_due = amount_paid); 

/*
Summary - Data is clean as per above checks 
*/

---------------------------------SUPPORT CONTACTS ANALYSIS--------------------

select * from PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_SUPPORT_CONTACTS limit 10;

select count(*) from PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_SUPPORT_CONTACTS;-- 1280

select  distinct count( *) from PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_SUPPORT_CONTACTS; --1280 no duplicates

--check contact_id null as pk | No null | Looks Good
select * from PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_SUPPORT_CONTACTS where contact_id is null;

--check customer_id null as pk | No null | Looks Good
select * from PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_SUPPORT_CONTACTS where customer_id is null;

--check range of created_at and resolved_at | No future dates | Looks Good
select min(created_at), max(created_at), min(resolved_at), max(resolved_at) from PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_SUPPORT_CONTACTS ;

--check nulls for created_at | No nulls | Looks Good
select created_at from PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_SUPPORT_CONTACTS 
where created_at is null;

--check nulls for resolved_at | 181 nulls | Expected as these are opn tickets | Looks Good
--#but i dont see any status or flag columns to check if tickets are open or closed
select * from PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_SUPPORT_CONTACTS 
where resolved_at is null;

--check created_at should be less than resolved_at always | 1280 after handling null | Looks good
select * from PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_SUPPORT_CONTACTS 
where created_at < coalesce(resolved_at, '9999-12-30 00:00:00.000');

select category, count(*) as count 
from PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_SUPPORT_CONTACTS 
group by 1
order by 2 desc;

/*
Summary of SUPPORT CONTACTS
- Data is clean as per above checks.
1. Just 1 addtion will be to add is_unresolved_flag column as TRUE where resolved_at is null else FALSE
2. Also to check performance, create time taken to resolve an issue
*/


--------------------------------PORTAL EVENTS ANALYSIS------------------------------------------------

select * from PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_PORTAL_EVENTS limit 10;

select count(*) from PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_PORTAL_EVENTS; --4810

select distinct count(*) from PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_PORTAL_EVENTS; --4810 No duplicates 

--check event_id as unique and null | No null and duplicates | Looks Good
select * from PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_PORTAL_EVENTS where event_id is null;

select event_id, count(*) as cnt from PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_PORTAL_EVENTS 
group by 1 
having cnt > 1;

--check customer id as foreign key | 1640 Null out of 4810 | 
--#Might be case of late arriving data | Needs backfill | For now need to create flag column in dbt
select * from PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_PORTAL_EVENTS where customer_id is null; --1640/4810

select * from PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_PORTAL_EVENTS where customer_id is not null; --3170/4810
--#How come customer ID is in decimal ? | To be cleaned 

--check event type distribution | No nulls | Looks good 
--277 support ticket open - need to check if they are unhappy ?  
select event_type, count(*) as count
from PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_PORTAL_EVENTS
group by 1;

--check range of event timestamp | No future dates | Looks Good
select min(event_timestamp), max(event_timestamp)
from PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_PORTAL_EVENTS;

--check null of event timestamp | No nulls | Looks Good 
select * from 
PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_PORTAL_EVENTS
where event_timestamp is null; 

/*
Summary of PORTAL EVENTS- 
1. 1640 Customer_ID are Nulls out of 4810 rows, might be case if late arriving data, for now lets create a flag
2. All Customer_ID is in decimal, need to clean this in dbt
3. 277 support ticket open as event type - need to check if customer are unhappy ?  
*/

---------------------------------------USAGE DAILY-------------------------------------

select * from PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_USAGE_DAILY limit 10;

select count(*) from PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_USAGE_DAILY ; -- 180990
select distinct count(*) from PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_USAGE_DAILY ; --180990 No Duplicates 

--Check Subscription_Id(only business key present) distribution
select subscription_id, count(*) as cnt
from PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_USAGE_DAILY
group by 1
order by 2 desc;

--check Subscription_Id null | No Nulls | Looks Good 
select * from PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_USAGE_DAILY where subscription_id is null;

--check date range of usage date | No future dates | Looks good
select min(usage_date), max(usage_date)
from PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_USAGE_DAILY;

--check null in usage date | No Nulls | Looks Good 
select * from PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_USAGE_DAILY where usage_date is null;

--check negative count or null in call_count, call_minutes, concurrent_peak | No null and no negative | Looks Good
select * from PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_USAGE_DAILY 
where 1=1
and call_count is null or call_minutes is null or concurrent_peak is null 
or call_count <0 or call_minutes <0 or concurrent_peak<0
;

--check combination of subscription_id and usage_data uniqueness | Combination can be a key | Looks Good 
select distinct subscription_id, usage_date 
from PENNINE_CONNECT_RAW_DEV.SYNTHETIC_DATA.TB_USAGE_DAILY; --180,990

/*
Summary of USAGE DAILY- Data is clean 
Need to analyze the data on concurrent_peak means 
*/

--With above  analysis I created model/staging in dbt
--------------------------------STAGING
select * from PENNINE_CONNECT_CURATED_DEV.STAGING.STG_CUSTOMERS limit 10;
select * from PENNINE_CONNECT_CURATED_DEV.STAGING.STG_SUBSCRIPTIONS limit 10;
select * from PENNINE_CONNECT_CURATED_DEV.STAGING.STG_BILLINGS limit 10;
select * from PENNINE_CONNECT_CURATED_DEV.STAGING.STG_SUPPORT_CONTACTS limit 10;
select * from PENNINE_CONNECT_CURATED_DEV.STAGING.STG_PORTAL_EVENTS limit 10;
select * from PENNINE_CONNECT_CURATED_DEV.STAGING.STG_USAGE_DAILY limit 10;

-----------------------------------Analysis before creating Intermediate----------------------------- 

--Customer having more than 1 subscription id | 105 Customers | 
select customer_id, count(subscription_id) as cnt
from PENNINE_CONNECT_CURATED_DEV.STAGING.STG_SUBSCRIPTIONS
group by 1
having cnt > 1
order by cnt desc;
--501 is having 3 as highest so lets take 501 example 

select * from PENNINE_CONNECT_CURATED_DEV.STAGING.STG_SUBSCRIPTIONS 
where 1=1
and customer_id = 501
order by go_live_date, subscription_id asc
;
--Product type as voip and mobile
--So customer + product_type should be combined

--calculate previous status and prev_cancelled_date
select *,
lag(status) over (partition by customer_id, product_type order by go_live_date, subscription_id) as prev_status,
lag(cancelled_date) over (partition by customer_id, product_type order by go_live_date, subscription_id) as prev_cancelled_date
from PENNINE_CONNECT_CURATED_DEV.STAGING.STG_SUBSCRIPTIONS
where 1=1
and customer_id = 501
and product_type = 'voip'
order by go_live_date, subscription_id
;
--derive of reactivation logic 
--reactivation logic  - prev_status = 'cancelled' and prev_cancelled_date is not null and golive_date > prev_cancelled_date


---------------------------------------------INTERMEDIATE Tables created using dbt------------------------------------

select distinct lifecycle_state from PENNINE_CONNECT_CURATED_DEV.INTERMEDIATE.INT_SUBSCRIPTION_LIFECYCLE;
-- pending_activation
-- fraud
-- voluntary_cancellation
-- reactivation
-- cancelled_before_go_live

SELECT lifecycle_state, count(*) as cnt FROM PENNINE_CONNECT_CURATED_DEV.INTERMEDIATE.INT_SUBSCRIPTION_LIFECYCLE
group by 1
order by cnt desc;
-- active	622
-- voluntary_cancellation	113
-- cancelled_before_go_live	32
-- fraud	22
-- pending_activation	10
-- reactivation	7

--Fact table should not contain cancelled_before_go_live(doa) and fraud 


SELECT * FROM PENNINE_CONNECT_CURATED_DEV.INTERMEDIATE.INT_SUBSCRIPTION_LIFECYCLE
where lifecycle_state = 'voluntary_cancellation';


------------------------------------------------MARTS(FACT table creation using dbt)------------------------------------------------
--Fact table should only contains active, voluntary_cancellation,reactivation

select * from PENNINE_CONNECT_CURATED_DEV.MARTS.FCT_SUBSCRIPTION_MONTHLY limit 10;
select count(*) from PENNINE_CONNECT_CURATED_DEV.MARTS.FCT_SUBSCRIPTION_MONTHLY; --15836

select lifecycle_state, count(*) as cnt
from PENNINE_CONNECT_CURATED_DEV.MARTS.FCT_SUBSCRIPTION_MONTHLY
group by 1;


select * from PENNINE_CONNECT_CURATED_DEV.INTERMEDIATE.INT_SUBSCRIPTION_LIFECYCLE
where customer_id = 2;

select * from PENNINE_CONNECT_CURATED_DEV.INTERMEDIATE.INT_SUBSCRIPTION_LIFECYCLE
where 1=1
and customer_id = 501
and product_type = 'voip'
order by go_live_date, subscription_id;


select * from PENNINE_CONNECT_CURATED_DEV.MARTS.FCT_SUBSCRIPTION_MONTHLY
where customer_id = 2
order by activity_month asc;

select * from PENNINE_CONNECT_CURATED_DEV.MARTS.FCT_SUBSCRIPTION_MONTHLY
where 1=1
and customer_id = 501
and product_type = 'voip'
order by activity_month asc;
--Go live Date : 2023-10-18
-- Cancelled Date : 2025-03-23

------------------------------------------FCT_CHURN_METRICS using dbt---------------------------------------
select * from PENNINE_CONNECT_CURATED_DEV.MARTS.FCT_CHURN_METRICS; --12 month 

select * from PENNINE_CONNECT_CURATED_DEV.INTERMEDIATE.INT_LEADING_INDICATOR_BASE;

----------SIGNAL ANALYSIS before creating indicator fact FCT_LEADING_INDICATOR_SCAN--------------------------
--These are signals from above all 6 tables analysis(mentioned in ppt slide 6-9) where i assumed these could be 
--indicator for churn

--signal 1
select * from PENNINE_CONNECT_CURATED_DEV.STAGING.STG_SUPPORT_CONTACTS where category = 'complaint'; --164

--signal 2
select * from PENNINE_CONNECT_CURATED_DEV.STAGING.STG_PORTAL_EVENTS where event_type = 'support_ticket_open'; --277

--signal 3
select * from PENNINE_CONNECT_CURATED_DEV.STAGING.STG_SUPPORT_CONTACTS where category = 'technical_fault'; --361

--signal 4
select * from PENNINE_CONNECT_CURATED_DEV.STAGING.STG_USAGE_DAILY limit 10;

--signal 5 
select * from PENNINE_CONNECT_CURATED_DEV.STAGING.STG_BILLINGS where status in ('unpaid','part_paid');--1340

--signal 6 
select * from PENNINE_CONNECT_CURATED_DEV.STAGING.STG_USAGE_DAILY where concurrent_peak >= 8; --21170


----------------------------------Fact table created using dbt--------------------------------------
select * from PENNINE_CONNECT_CURATED_DEV.MARTS.FCT_LEADING_INDICATOR_SCAN;





