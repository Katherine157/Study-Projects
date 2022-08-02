--1
--В каких городах больше одного аэропорта?

--/посчитала количество городов, сделала группировку по городам
--/потом добавила фильтрацию, чтобы отсеять города с одним аэропортом

select city, count (city) quantity
from airports a 
group by city 
having count (city) > 1 


--2
--В каких аэропортах есть рейсы, выполняемые самолетом с максимальной дальностью перелета?
--Подзапрос

--/отсортировала через подзапрос range от большего к меньшему
--/присоединила таблицу с информацией о аэропортах, чтобы взять название городов

select distinct departure_airport as airport, a2.airport_name, range 
from flights f 
join airports a2 on a2.airport_code = f.departure_airport
join (
	select aircraft_code, range 
	from aircrafts a 
	order by range desc limit 1) t on t.aircraft_code = f.aircraft_code 


--3
--Вывести 10 рейсов с максимальным временем задержки вылета
--Оператор LIMIT

--/посчитала задержку вылета 
--/добавила условие, что задержка не должна быть null
--/отсортировала от большей задержки к меньшей и оставила первые 10 значений

select flight_id, flight_no, actual_departure - scheduled_departure as delay 
from flights f 
where actual_departure - scheduled_departure is not null
order by actual_departure - scheduled_departure desc limit 10


--4
--Были ли брони, по которым не были получены посадочные талоны?
--Верный тип JOIN

--/к таблице с бронированием присоединила таблицу с билетами
--/затем сделала полное присоединение таблицы с посадочными талонами
--/добавила фильтрацию, чтобы вывести бронирования без билетов

select distinct b.book_ref, bp.ticket_no
from bookings b
join tickets t on b.book_ref = t.book_ref
full join boarding_passes bp on t.ticket_no = bp.ticket_no 
where bp.ticket_no is null 


--5
--Найдите количество свободных мест для каждого рейса, их % отношение к общему количеству мест в самолете.
--Добавьте столбец с накопительным итогом - суммарное накопление количества вывезенных пассажиров из каждого аэропорта на каждый день. 
--Т.е. в этом столбце должна отражаться накопительная сумма - сколько человек уже вылетело из данного аэропорта на этом или более ранних рейсах в течении дня.
--Оконная функция
--Подзапросы или/и cte

--/через cte сосчитала количество всех мест по каждому самолету
--/через cte2 сосчитала занятые места по каждому рейсу
--/сосчитала количество свободных мест и процентное соотношение
--/посчитала накопительный итог

with cte as (
	select count(seat_no)::numeric as seat_all, aircraft_code 
	from seats s 
	group by aircraft_code),
cte2 as (
	select count (bp.boarding_no)::numeric seat_busy, f.flight_id, aircraft_code, departure_airport, actual_departure 
	from boarding_passes bp
	join flights f on f.flight_id = bp.flight_id 
	where f.actual_departure is not null 
	group by f.flight_id)
select flight_id, seat_all - seat_busy as seat_free, seat_busy, ((seat_all - seat_busy) / seat_all * 100)::numeric(6,2) as percent,
sum(cte2.seat_busy) over (partition by cte2.departure_airport, cte2.actual_departure::date order by cte2.actual_departure) as people, 
departure_airport, actual_departure
from cte
join cte2 on cte.aircraft_code = cte2.aircraft_code


--6
--Найдите процентное соотношение перелетов по типам самолетов от общего количества.
--Подзапрос или окно
--Оператор ROUND

--/через подзапрос посчитала общее количество рейсов
--/затем посчитала процент соотношения перелетов по самолетам к общему количеству рейсов
--/сгрупировала по коду самолета

select round(count (aircraft_code)::numeric / t.count * 100) percent, aircraft_code
from (
	select count (flight_id)
	from flights f ) t, flights f 
group by aircraft_code, t.count


--7
--Были ли города, в которые можно  добраться бизнес - классом дешевле, чем эконом-классом в рамках перелета?
--CTE

--/через cte создала логику с местами "Эконом"
--/ через cte2 создала логику с местами "Бизнес"
--/через cte3 вывела названия городов для каждого аэропорта
--/задала условие, что бы сравнить стоимость 

with cte as (
	select distinct tf.flight_id, fare_conditions as economy, amount as amount_economy
	from ticket_flights tf 
	where fare_conditions like 'Economy'
	order by tf.flight_id),
cte2 as (
	select distinct flight_id, fare_conditions as business, amount as amount_business
	from ticket_flights tf 
	where fare_conditions like 'Business'
	order by flight_id),
cte3 as (
	select distinct f2.flight_id, f2.arrival_airport, a.city 
	from flights f2 
	join airports a on a.airport_code = f2.arrival_airport)
select distinct cte3.city
from cte
join cte2 on cte.flight_id = cte2.flight_id
join cte3 on cte.flight_id = cte3.flight_id 
where cte.flight_id = cte2.flight_id and cte.amount_economy > cte2.amount_business 


--8
--Между какими городами нет прямых рейсов?
--Декартово произведение в предложении FROM
--Самостоятельно созданные представления
--Оператор EXCEPT

--/создала представление для получения каждым аэропортом название города 
--/задала условие, что бы отсеить повторения и зеркальные варианты
--/убрала повторения маршрутов 

create view pair_city as 
select departure_city, arrival_city
from (
	select f.flight_id, f.departure_airport, a.airport_code, a.city as departure_city
	from flights f 
	join airports a on f.departure_airport = a.airport_code) t 
join (
	select distinct f.flight_id, f.arrival_airport, a.airport_code, a.city as arrival_city
	from flights f 
	join airports a on f.arrival_airport = a.airport_code) t2 on t.flight_id = t2.flight_id

select a.city, a2.city
from airports a, airports a2 
where a.city != a2.city  and a.city > a2.city
except 
select departure_city, arrival_city 
from pair_city f 

--9
--Вычислите расстояние между аэропортами, связанными прямыми рейсами, 
--Сравните с допустимой максимальной дальностью перелетов  в самолетах, обслуживающих эти рейсы
--Оператор RADIANS или использование sind/cosd
--CASE 

--/присоединила два раза таблицу с информацией о аэропортах, чтобы получить координаты 
--/посчитала расстояние
--/сделала сравнение

select distinct a.airport_name airport_from, a2.airport_name airport_to, a3.range, a3.aircraft_code,
round(acos(sind(a.latitude)*sind(a2.latitude) + cosd(a.latitude)  * cosd(a2.latitude) * cosd(a.longitude - a2.longitude)) * 6371) as distance,
	case 
		when (acos(sind(a.latitude)*sind(a2.latitude) + cosd(a.latitude)  * cosd(a2.latitude) * cosd(a.longitude - a2.longitude)) * 6371) < a3.range then 'good'
		when (acos(sind(a.latitude)*sind(a2.latitude) + cosd(a.latitude)  * cosd(a2.latitude) * cosd(a.longitude - a2.longitude)) * 6371) > a3.range then 'bad'
	end
from flights f 
join airports a on f.departure_airport = a.airport_code 
join airports a2 on f.arrival_airport = a2.airport_code 
join aircrafts a3 on f.aircraft_code = a3.aircraft_code 
