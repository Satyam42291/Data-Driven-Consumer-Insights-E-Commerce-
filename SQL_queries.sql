use carrdb;

-- question 1
select 
  sku_name,
  sum(ordered_revenue) / nullif(sum(ordered_units), 0) as avg_selling_price
from sales_data
group by sku_name
order by avg_selling_price desc
limit 1;

-- question 2
with total_skus as (
  select count(distinct sku_name) as total from sales_data
),
revenue_skus as (
  select count(distinct sku_name) as with_revenue 
  from sales_data 
  where ordered_revenue > 0
)
select 
  (with_revenue * 100.0) / total as revenue_percentage
from total_skus, revenue_skus;

-- brownie point
select distinct sku_name
from sales_data
where sku_name not in (
  select distinct sku_name 
  from sales_data 
  where feed_date > '2022-07-31' and ordered_revenue > 0
);

-- question 3
select feed_date, sum(ordered_revenue) as total_revenue
from sales_data
group by feed_date
order by total_revenue desc
limit 5;

-- question 4
select
  case 
    when feed_date between '2022-07-01' and '2022-07-14' then 'pre_sale'
    when feed_date = '2022-07-17' then 'sale_day'
    when feed_date between '2022-07-17' and '2022-07-31' then 'post_sale'
  end as period,
  avg(ordered_revenue) as avg_revenue
from sales_data
where feed_date between '2022-07-10' and '2022-07-24'
group by period;

-- question 5
with category_growth as (
  select 
    category,
    subcategory,
    sum(case when feed_date < '2022-07-01' then ordered_revenue else 0 end) as rev_early,
    sum(case when feed_date >= '2022-07-01' then ordered_revenue else 0 end) as rev_late
  from sales_data
  group by category, subcategory
)
select *,
  case 
    when rev_early = 0 then null
    else (rev_late - rev_early) * 1.0 / rev_early
  end as growth_rate
from category_growth
order by growth_rate asc;

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
