create database paintings;
use paintings;

select* from artist 
select* from canvas
select* from image_link 
select* from museum 
select* from product_size 
select* from subject 
select* from work 
select*from museum_hours 

--1. fetch all paintaing which are not displayed on any museums.

select museum_id from museum 
where museum_id is null 

--2.Are there museums wihtout any painting?

select * from museum m
where not exists( select 1 from work w where w.museum_id=m.museum_id)

--3) How many paintings have an asking price of more than their regular price? 

select * from product_size 
where sale_price > regular_price 

--4) Identify the paintings whose asking price is less than 50% of its regular price

select * from product_size 
where sale_price <(regular_price/2)

--5) Which canva size costs the most?

select c.size_id
from canvas c
join product_size p
on  c.size_id=p.size_id
where p.sale_price=(select max(sale_price) from product_size)

--6) Delete duplicate records from work, product_size, subject and image_link tables

select*from work 
select* from product_size
select * from subject 
select * from image_link

with cte as(
select work_id, row_number() over( partition by work_id order by work_id) rnk
from work) 

delete from work
where work_id in(
				select work_id from cte 
				where rnk>1)

with cte as(
select work_id, row_number() over( partition by work_id order by work_id) rnk
from product_size) 

delete from product_size
where work_id in(
				select work_id from cte 
				where rnk>1)

with cte as(
select work_id, row_number() over( partition by work_id order by work_id) rnk
from [subject ]) 

delete from [subject ]
where work_id in(
				select work_id from cte 
				where rnk>1)

with cte as(
select work_id, row_number() over( partition by work_id order by work_id) rnk
from image_link) 

delete from image_link
where work_id in(
				select work_id from cte 
				where rnk>1)

--7) Identify the museums with invalid city information in the given dataset

 select* from museum 
 where city like'[0-9]%'

 --8) Museum_Hours table has 1 invalid entry. Identify it and remove it

with cte as(
			select *, row_number() over( partition by museum_id,day order by(select null)) rnk
			from museum_hours) 
delete from museum_hours
where museum_id in(
					select museum_id from cte 
					where rnk>1)

--9) Fetch the top 10 most famous painting subject

select* from subject 
select*from work 

select*from
		(select s.subject,count(1) as cnt_subjects
		,ROW_NUMBER() over(order by count(1)desc)rnk
		from work w
		join [subject ] s
		on w.work_id=s.work_id
		group by s.subject) a
where a.rnk<=10 

--10) Identify the museums which are open on both Sunday and Monday. Display museum name, city.

select*from museum_hours
select*from museum 

SELECT m.name, m.city
FROM museum m
JOIN museum_hours mh ON m.museum_id = mh.museum_id
WHERE mh.day IN ('Sunday', 'Monday')
GROUP BY m.museum_id, m.name, m.city
HAVING COUNT(DISTINCT mh.day) = 2;

--11) How many museums are open every single day?
select*from museum_hours
select*from museum 

select mh.museum_id,m.name,count(distinct mh.day)
from museum_hours mh
join museum m
on mh.museum_id=m.museum_id
group by mh.museum_id,m.name
having count(distinct mh.day )=7

--12) Which are the top 5 most popular museum? (Popularity is defined based on most no of paintings in a museum)
select*from museum
select* from work 

select m.name as museum, m.city,m.country,x.no_of_painintgs
	from (	select m.museum_id, count(1) as no_of_painintgs
			, row_number() over(order by count(1) desc) as rnk
			from work w
			join museum m on m.museum_id=w.museum_id
			group by m.museum_id) x
	join museum m on m.museum_id=x.museum_id
	where x.rnk<=5;

--13) Who are the top 5 most popular artist? (Popularity is defined based on most no of paintings done by an artist)

select*from artist
select*from work 

select a.full_name,a.nationality,x.cnt_paintings
from(
		select w.artist_id, count(1) as cnt_paintings ,row_number() over( order by count(1) desc) rnk 
		from artist a
		join work w
		on a.artist_id=w.artist_id
		group by w.artist_id) x 
join artist a
on a.artist_id=x.artist_id
where x.rnk<=5

--14) Display the 3 least popular canva sizes

SELECT label, x.ranking, x.no_of_paintings
FROM (
    SELECT cs.size_id,
           cs.label,
           COUNT(1) AS no_of_paintings,
           DENSE_RANK() OVER (ORDER BY COUNT(1) DESC) AS ranking
    FROM work w
    JOIN product_size ps ON ps.work_id = w.work_id
    JOIN canvas cs ON cs.size_id = ps.size_id 
    GROUP BY cs.size_id, cs.label
) x
WHERE x.ranking <= 3;

--15) Which museum is open for the longest during a day. Dispay museum name, state and hours open and which day?
select*from museum
select* from museum_hours

SELECT museum_name, 
       state AS city, 
       day, 
       [open], 
       [close], 
       DATEDIFF(MINUTE, CAST([open] AS TIME), CAST([close] AS TIME)) AS duration
FROM (
    SELECT m.name AS museum_name, 
           m.state, 
           mh.day, 
           mh.[open], 
           mh.[close],
           DATEDIFF(MINUTE, 
                    CAST([open] AS TIME), 
                    CAST([close] AS TIME)) AS duration,
           RANK() OVER (ORDER BY DATEDIFF(MINUTE, 
                                          CAST([open] AS TIME), 
                                          CAST([close] AS TIME)) DESC) AS rnk
    FROM museum_hours mh
    JOIN museum m ON m.museum_id = mh.museum_id
) AS x
WHERE x.rnk = 1;

--16) Which museum has the most no of most popular painting style?

select*from museum
select*from work

with pop_style as 
			(select style
			,rank() over(order by count(1) desc) as rnk
			from work
			group by style),
		cte as
			(select w.museum_id,m.name as museum_name,ps.style, count(1) as no_of_paintings
			,rank() over(order by count(1) desc) as rnk
			from work w
			join museum m on m.museum_id=w.museum_id
			join pop_style ps on ps.style = w.style
			where w.museum_id is not null
			and ps.rnk=1
			group by w.museum_id, m.name,ps.style)
	select museum_name,style,no_of_paintings
	from cte 
	where rnk=1;

--17) Identify the artists whose paintings are displayed in multiple countries

select*from artist
select*from work

with cte as
		(select distinct a.full_name as artist
		, m.country
		from work w
		join artist a on a.artist_id=w.artist_id
		join museum m on m.museum_id=w.museum_id)

	select artist,count(1) as no_of_countries
	from cte
	group by artist
	having count(1)>1
	order by no_of_countries desc


--21) Which are the 3 most popular and 3 least popular painting styles?

select*from work 

with cte as( 
		select style from(
					select style, row_number() over (order by count(style) desc) most_popular
					from work 
					group by style) e
		where e.most_popular<=3),

 cte2 as(
 select style from(
					select style, row_number() over (order by count(style) asc) least_popular
					from work 
					group by style) e
		where e.least_popular<=3 and style is not null )

select style,
	'most popular' as popularity 
from cte 
union all 
select style,
	'least popular' as popularity 
from cte2 








