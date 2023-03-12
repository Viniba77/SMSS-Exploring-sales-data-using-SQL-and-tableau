use [portfoliodb]

select * from [dbo].[sales_data_sample]

select distinct(status) from [dbo].[sales_data_sample] 
select distinct(country) from [dbo].[sales_data_sample] ---nice to plot--
select distinct (productline) from [dbo].[sales_data_sample] --nice to plot
select distinct( dealsize) from [dbo].[sales_data_sample]

select productline , sum(sales) revenue
from [dbo].[sales_data_sample]
group by productline
order by 2 desc


ALTER TABLE [dbo].[sales_data_sample] 
alter COLUMN sales decimal(22,2) 

select year_id,sum(sales) revenue
from [dbo].[sales_data_sample]
group by year_id
order by revenue

select distinct(month_id) from [dbo].[sales_data_sample]
where year_id = '2003'
select distinct(month_id) from [dbo].[sales_data_sample]
where year_id = '2004'
select distinct(month_id) from [dbo].[sales_data_sample]
where year_id = '2005'

select dealsize,sum(sales) revenue from   [dbo].[sales_data_sample]
group by dealsize
order by revenue 


----What was the best month for sales in a specific year? How much was earned that month? 
select month_id,sum(sales) revenue
from [dbo].[sales_data_sample]
group by month_id
order by revenue desc

--november month seems the best month for sales as the revenue is maximum---
select productline,sum(sales),count(ordernumber) freq,month_id
from [dbo].[sales_data_sample]
where month_id = '11' and year_id ='2004'
group by month_id,productline
order by productline

select productline,sum(sales),count(ordernumber) freq,month_id
from [dbo].[sales_data_sample]
where month_id = '11' and year_id ='2003'
group by month_id,productline
order by productline

select productline,sum(sales),count(ordernumber) freq,month_id
from [dbo].[sales_data_sample]
where month_id = '11' and year_id ='2003'
group by month_id,productline
order by productline



DROP TABLE if EXISTS #rfm

;with rfm as(

select customername,sum(sales)monetary_alue,avg(sales) average_monetary_value,count(ordernumber) numbero_rders,
max(orderdate) last_orderdate,(
select max(orderdate)
 from [dbo].[sales_data_sample])max_order_date,
datediff(DD,max(orderdate),(select max(orderdate) 
from  [dbo].[sales_data_sample])) recency 
from  [dbo].[sales_data_sample]
group by customername),

rfm_calc as

(

select r.*,
       NTILE(4)over(order by recency) rfm_recency,
	  NTILE(4)over(order by numbero_rders) rfm_frequency,
	   NTILE(4)over(order by monetary_alue) rfm_monetary

from rfm as r

)

select c.*,rfm_recency+rfm_frequency+rfm_monetary as rfm_cell,
cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_monetary as varchar) as rfm_cellstring
into #rfm
from rfm_calc c


select customername,rfm_recency,rfm_frequency,rfm_monetary,
   case
     when rfm_cellstring in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers'  --lost customers
		when rfm_cellstring in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		when rfm_cellstring in (311, 411, 331) then 'new customers'
		when rfm_cellstring in (222, 223, 233, 322) then 'potential churners'
		when rfm_cellstring in (323, 333,321, 422, 332, 432) then 'active' --(Customers who buy often & recently, but at low price points)
		when rfm_cellstring in (433, 434, 443, 444) then 'loyal'

	end as rfm_segment

 from #rfm



 select distinct OrderNumber,stuff ( 

(select','+PRODUCTCODE
 from [dbo].[sales_data_sample] p
 where ordernumber in
 (
 select ordernumber 
 from(
 select ORDERNUMBER, count(*) rn
				FROM [PortfolioDB].[dbo].[sales_data_sample]
				where STATUS = 'Shipped'
				group by ORDERNUMBER
			
	)m
	where rn =3 
	)
	and p.ORDERNUMBER = s.ORDERNUMBER
	for xml path(''))
	, 1, 1, '') ProductCodes
	 
from [dbo].[sales_data_sample] s
order by 2 desc