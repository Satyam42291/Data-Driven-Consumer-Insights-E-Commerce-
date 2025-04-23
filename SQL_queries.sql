use carrdb;

-- create table Glance_Views
-- (
-- id	int primary key,
-- SKU_NAME	varchar(255),
-- FEED_DATE	date,
-- VIEWS	int,
-- UNITS   int
-- );
-- load data infile 'Glance_Views.csv' into table Glance_Views
-- fields terminated by ','
-- ignore 1 lines;
-- SHOW VARIABLES LIKE "secure_file_priv";
-- select * from Glance_Views;
-- select count(id) from Glance_Views;

-- create table Sales_Data
--  (
-- id	int primary key,
-- SKU_NAME	varchar(255),
-- FEED_DATE	date,
-- CATEGORY varchar(255),
-- SUB_CATEGORY varchar(255),
-- ORDERED_REVENUE double,
-- ORDERED_UNITS int,
-- REP_OOS double
-- );
-- load data infile 'Sales_Data.csv' into table Sales_Data
-- fields terminated by ','
-- ignore 1 lines;
-- SHOW VARIABLES LIKE "secure_file_priv";
-- select * from Sales_Data;
-- select count(id) from Sales_Data;


-- question 1
select 
  sku_name,
  sum(ordered_revenue) / nullif(sum(ordered_units), 0) as avg_selling_price
from sales_data
group by sku_name
order by avg_selling_price desc
limit 1;


-- question 2
select
  (count(sku_name) * 100.0) / (select count(distinct sku_name) from sales_data) as revenue_percentage
from (
  select sku_name, sum(ordered_revenue) as total_revenue
  from sales_data
  group by sku_name
  having total_revenue > 0
) as revenue_skus;

-- brownie point
with pre_august_sales as (
  select sku_name
  from sales_data
  where feed_date between '2019-07-01' and '2019-07-31'
  group by 1
  having sum(ORDERED_UNITS) > 0
),
august_sales as (
  select sku_name
  from sales_data
  where feed_date > '2019-07-31'
  group by 1
  having sum(ORDERED_UNITS) > 0
)
select distinct sku_name
from sales_data 
where sku_name in (select sku_name from pre_august_sales) and sku_name not in (select sku_name from august_sales);


-- question 3
select feed_date, round(sum(ordered_revenue), 2) as total_revenue
from sales_data
group by feed_date
order by total_revenue desc
limit 5;


-- question 4
select
  case 
    when feed_date between '2019-07-01' and '2019-07-14' then 'pre_sale'
    when feed_date between '2019-07-15' and '2019-07-16' then 'sale_day'
    when feed_date between '2019-07-17' and '2019-07-31' then 'post_sale'
  end as period,
  round(avg(ordered_revenue), 2) as avg_revenue
from sales_data
where feed_date between '2019-07-01' and '2019-07-31'
group by period;


-- question 5
with category_growth as (
  select 
    category,
    sub_category,
    sum(case when feed_date < '2019-07-01' then ordered_revenue else 0 end) as rev_early,
    sum(case when feed_date >= '2019-07-01' then ordered_revenue else 0 end) as rev_late
  from sales_data
  group by category, sub_category
),
relative_growth as (
select *,
  case 
    when rev_early = 0 then null
    else (rev_late - rev_early) * 1.0 / rev_early
  end as growth_rate
from category_growth
order by growth_rate asc
)
select category, sub_category, growth_rate 
from relative_growth g1
where growth_rate = (select min(growth_rate) from relative_growth g2 where g2.category=g1.category);


-- question 6 (to identify anomalies)
select * from sales_data where ordered_units = 0 and ordered_revenue > 0;
select * from sales_data where rep_oos < 0 or rep_oos > 1;

-- question 7
with combined as (
  select 
    s.feed_date,
    s.sku_name,
    g.views,
    g.units,
    s.ordered_revenue,
    s.ordered_units
  from sales_data s
  join glance_views g on s.feed_date = g.feed_date and s.sku_name = g.sku_name
  where s.sku_name = 'c120[h:8nv'
)
select 
  feed_date,
  units * 1.0 / nullif(views, 0) as unit_conversion,
  ordered_revenue * 1.0 / nullif(ordered_units, 0) as asp
from combined;
