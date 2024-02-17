-- PHÂN TÍCH DỮ LIỆU - DATA ANALYSIS
use VIETTEL
go

--Lợi nhuận và doanh thu theo từng tháng/quý
select year(O.delivered_at) as 'year', month(O.delivered_at) as 'month', 
		sum(OD.sale_price) as 'revenue', sum(OD.sale_price-I.cost) as 'profit'
from order_details OD, orders O, items I
where (OD.order_id=O.order_id) and (O.status='Complete') and (OD.item_id=I.id)
group by year(O.delivered_at), month(O.delivered_at)
order by 'year' asc, 'month' asc

--So sánh tỉ lệ lợi nhuận (profit/sale) theo từng tiểu bang (state) trong năm 2021?
-- (Chọn 2021 vì đây là năm gần nhất có dữ liệu đủ 12 tháng, trong khi năm 2022 mới chỉ có dữ liệu của 6 tháng đầu năm)
select C.state, C.country, sum(OD.sale_price-I.cost)/sum(OD.sale_price) as 'profit_margin'
from customers C, order_details OD, orders O, items I
where (C.id=O.cus_id) and (O.order_id=OD.order_id) and (OD.item_id=I.id)
group by C.state, C.country
order by C.state

--So sánh doanh thu và lợi nhuận theo ngành hàng (category)
select I.category, sum(OD.sale_price) as 'revenue',
					sum(OD.sale_price-I.cost) as 'profit'
from items I, order_details OD, orders O
where (I.id=OD.item_id) and (OD.order_id=O.order_id) and (O.status='Complete')
group by I.category

--Có bao nhiêu sản phẩm bị trả lại (return)? Danh mục sản phẩm nào có tỉ lệ trả lại cao nhất?
select I.brand, I.category, count(*) as 'quantity'
from items I, order_details OD, orders O
where (I.id=OD.item_id) and (OD.order_id=O.order_id) and (O.status='Returned')
group by I.brand, I.category
order by I.brand, I.category

select I.category,
       sum(case when O.status='Returned' then 1 else 0 end) as 'returned',
	   sum(case when O.status='Returned' then 1 else 0 end)*1.0/count(*) as 'percent'
from items I
join order_details OD on i.id = OD.item_id
join orders O on od.order_id = O.order_id
group by I.category
order by 'percent' desc;

--Các sản phẩm thường được khách hàng mua cùng nhau (cross-selling items)
select I1.category as category1, I2.category as category2, count(*) as times
from order_details OD1
	join order_details OD2 on OD1.order_id = OD2.order_id and OD1.item_id < OD2.item_id
	join items I1 on OD1.item_id = I1.id
	join items I2 on OD2.item_id = I2.id
where I1.category!=I2.category
group by I1.category, I2.category
order by times desc




select O.order_id, O.created_at, O.delivered_at,
		DATEDIFF(second, O.created_at, O.delivered_at)*1.0/86400 as 'day(s)'
from orders O
where O.status='Complete'
order by 'day(s)' desc

--Thời gian trung bình để đơn hàng đến tay khách theo từng tiểu bang (state)
select C.state, C.country,
		avg(DATEDIFF(second, O.created_at, O.delivered_at)*1.0/86400) as 'avg_deli_time (days)'
from customers C
	join orders O on C.id=O.cus_id
where O.delivered_at is not null
group by C.state, C.country
order by 'avg_deli_time (days)' desc

--Khách hàng thường truy cập vào ứng dụng từ nguồn nào? Có bao nhiêu trong số đó đã mua hàng?

select E.traffic_src,
		sum(case when E.sequence_number=1 then 1 else 0 end) as 'accessed',
		sum(case when E.event_type='purchase' then 1 else 0 end) as 'purchased'
from events E
group by E.traffic_src
order by 'purchased' desc


--Phân tích Customer Segment bằng mô hình RFM 
with RFM_base
as(
	select C.id,
			(datediff(second, max(O.created_at), convert(datetime2(3), getdate()))/86400) as 'R',
			(count(distinct O.created_at)) as 'F',
			round(sum(OD.sale_price), 2) as 'M'
	from customers C
		left join orders O on C.id=O.cus_id
		left join order_details OD on O.order_id=OD.order_id
	where O.status!='Cancelled'
	group by C.id)
select B.id, S.RFM_Overall, SS.Segment
from RFM_base B
	join (SELECT id,
				CONCAT(NTILE(5) OVER (ORDER BY R DESC),
						NTILE(5) OVER (ORDER BY F ASC), 
						NTILE(5) OVER (ORDER BY M ASC)) as RFM_Overall
			FROM RFM_base) as S on B.id=S.id
	join segment_scores SS on S.RFM_Overall=SS.Scores
group by B.id, S.RFM_Overall, SS.Segment
order by B.id


with time_on_page
as(
	select E.session_id,
			(DATEDIFF(second, min(E.created_at), max(E.created_at)))*1.0 as 'time_on_page'
	from events E
	group by E.session_id)
select round(avg(TP.time_on_page), 1) as 'avg_time_on_page(s)'
from time_on_page TP
