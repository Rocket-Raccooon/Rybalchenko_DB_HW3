-- Рыбальченко Елена Павловна
-- Системы хранения и обработки данных
-- Домашнее задание №3
-- "Группировка данных и оконные функции"

-- Цель:
-- Научиться группировать и агрегировать данные,
-- считать на их основе множество показателей

-- 0.Создать таблицы со следующими структурами
-- и загрузить данные из csv-файлов. 

-- ОТВЕТ:
-- Создание таблицы customer:
drop table if exists customer_hw3;
create table if not exists customer_hw3(
customer_id int4 
,first_name varchar(50)
,last_name varchar(50)
,gender text
,DOB varchar(50)
,job_title varchar(50)
,job_industry_category varchar(50)
,wealth_segment varchar(50)
,deceased_indicator varchar(50)
,owns_car varchar(30)
,address varchar(50)
,postcode varchar(30)
,state varchar(30)
,country varchar(30)
,property_valuation int4
);

-- Создание таблицы transaction:
drop table if exists transaction_hw3;
create table if not exists transaction_hw3(
 transaction_id int4 
,product_id int4 
,customer_id int4 
,transaction_date varchar(30)
,online_order varchar(30)
,order_status varchar(30)
,brand varchar(30)
,product_line varchar(30)
,product_class varchar(30)
,product_size varchar(30)
,list_price float4
,standart_cost float4
)

-- 1. Вывести распределение (количество) клиентов по сферам деятельности,
-- отсортировав результат по убыванию количества. 

-- ОТВЕТ:

select job_industry_category, count(*) as cnt_job_industry
from customer_hw3 ch 
group by job_industry_category
order by cnt_job_industry desc;


-- 2. Найти сумму транзакций за каждый месяц по сферам деятельности, 
-- отсортировав по месяцам и по сфере деятельности.

-- ОТВЕТ:

select date_trunc('month', transaction_date::date) as transaction_date_month
	,job_industry_category as ji_category 
	,sum(transaction_id) as sum_transaction
from transaction_hw3 th  
join customer_hw3 ch on th.customer_id = ch.customer_id 
group by date_trunc('month', transaction_date::date),ji_category
order by transaction_date_month, ji_category  


-- 3. Вывести количество онлайн-заказов для всех брендов в рамках
-- подтвержденных заказов клиентов из сферы IT.

-- ОТВЕТ:

select th.brand  	
	,count(th.online_order) as cnt_online
from transaction_hw3 th  
join customer_hw3 ch  on th.customer_id = ch.customer_id  
where ch.job_industry_category = 'IT' and th.order_status like 'App%'
group by brand

-- 4. Найти по всем клиентам сумму всех транзакций (list_price), 
-- максимум, минимум и количество транзакций,
-- отсортировав результат по убыванию суммы транзакций и количества клиентов. 
-- Выполните двумя способами: используя только group by 
-- и используя только оконные функции. 
-- Сравните результат.

-- ОТВЕТ:

-- 4.1 groub by:

select ch.customer_id 
	,sum(list_price) as sum_list_price
	,count(list_price) as cnt_list_price
	,max(list_price) as max_list_price
	,min(list_price) as min_list_price
from transaction_hw3 th  
join customer_hw3 ch on th.customer_id = ch.customer_id 
group by ch.customer_id
order by sum_list_price desc, cnt_list_price desc

-- 4.2 Оконные функции

select 
	th.customer_id -- захотим найти уникальное -- ставим distinct
	,sum(coalesce(list_price,0))  over (partition by th.customer_id) as sum_list_price 
	,count(list_price) over (partition by th.customer_id) as cnt_list_price
	,max(list_price) over (partition by th.customer_id) as max_list_price
	,min(list_price) over (partition by th.customer_id) as min_list_price
from transaction_hw3 th 
order by sum_list_price desc, cnt_list_price desc

--Количество строк
select count(*)
from transaction_hw3 th 

-- Выводы:
-- При использовании оконных функций исходная таблица сохранилась,
-- количество строк такое же, к ней добавились новые, сагрегированные поля.
-- group by выдает только сгруппированные данные,количество строк меньше, 
-- т.к.исходная таблица не выводится.


-- 5. Найти имена и фамилии клиентов с минимальной/максимальной суммой транзакций 
-- за весь период (сумма транзакций не может быть null). Напишите отдельные запросы
-- для минимальной и максимальной суммы.

-- ОТВЕТ:
 --min_sum:
select
	 ch.first_name
	,ch.last_name 
	,sum(coalesce(list_price,0)) over (partition by th.customer_id order by th.transaction_date::date  asc)
		as sum_list_price 
from transaction_hw3 th 
join customer_hw3 ch on th.customer_id = ch.customer_id 
order by sum_list_price asc
limit(30)

 --max_sum:
select
	 ch.first_name
	,ch.last_name 
	,sum(coalesce(list_price,0)) over (partition by th.customer_id order by th.transaction_date::date  desc)
		as sum_list_price 
from transaction_hw3 th 
join customer_hw3 ch on th.customer_id = ch.customer_id 
order by sum_list_price desc
limit(1)

-- 6. Вывести только самые первые транзакции клиентов.
-- Решить с помощью оконных функций.

-- ОТВЕТ:

-- Идея заключалась в том, чтобы отобрать транзакции с row_number = 1, но не удалось это сделать с помощью  where

select 
    th.customer_id
	,ch.last_name 
	,transaction_id 
		as first_transaction 
	,row_number() over (partition by th.customer_id order by th.transaction_date::date  asc) as rn
from transaction_hw3 th 
join customer_hw3 ch on th.customer_id = ch.customer_id 
--where rn = 1
order by th.customer_id asc

-- 7. Вывести имена, фамилии и профессии клиентов, между транзакциями которых был
-- максимальный интервал (интервал вычисляется в днях).

-- ОТВЕТ:

select 
	first_name
	,last_name
	,job_title
	,date_trunc('day',transaction_date::date) as transaction_date_day -- захотим найти уникальное -- ставим distinct
	,lag(date_trunc('day',transaction_date::date)) over (partition by  th.customer_id order by date_trunc('day',transaction_date::date)) as lag_transaction_date_day
	,coalesce(date_trunc('day',transaction_date::date) - lag(date_trunc('day',transaction_date::date))
		over (partition by  th.customer_id order by date_trunc('day',transaction_date::date)),'0') as days_delta
from customer_hw3 ch 
join transaction_hw3 th on th.customer_id = ch.customer_id 
order by days_delta desc
limit(1)



