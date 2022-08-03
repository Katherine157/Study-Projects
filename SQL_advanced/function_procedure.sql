--6 задание -- внесение тестовых данных

create or replace procedure insert_test_data(value int) as $$
declare 
		bol boolean = (select floor(random()*2));
	begin
		for vi in 1..value*1
		loop
			insert into account (id, name)
			values (uuid_generate_v4(), 
			(select repeat(substring('абвгдеёжзийклмнопрстуфхцчшщьыъэюя',1,(random()*33)::integer),(random()*10)::integer)));
		end loop;
		for i in 1..value*2
		loop
			insert into contact (id, last_name, first_name, account_id)
			values (uuid_generate_v4(),
			(select repeat(substring('абвгдеёжзийклмнопрстуфхцчшщьыъэюя',1,(random()*33)::integer),(random()*10)::integer)),
			(select repeat(substring('абвгдеёжзийклмнопрстуфхцчшщьыъэюя',1,(random()*33)::integer),(random()*10)::integer)),
			(select id from account order by random () limit 1));
		end loop;
		for i in 1..value*1
		loop
			insert into "user" (id, last_name, first_name, dismissed)
			values (uuid_generate_v4(),
			(select repeat(substring('абвгдеёжзийклмнопрстуфхцчшщьыъэюя',1,(random()*33)::integer),(random()*10)::integer)),
			(select repeat(substring('абвгдеёжзийклмнопрстуфхцчшщьыъэюя',1,(random()*33)::integer),(random()*10)::integer)), 
			(select floor::boolean(random()*2));
		end loop;
		for i in 1..value*5
		loop
			insert into courier (id, from_place, where_place, name, account_id, contact_id, description, user_id, status, created_date)
			values (uuid_generate_v4(),
			(select repeat(substring('абвгдеёжзийклмнопрстуфхцчшщьыъэюя',1,(random()*33)::integer),(random()*10)::integer)),
			(select repeat(substring('абвгдеёжзийклмнопрстуфхцчшщьыъэюя',1,(random()*33)::integer),(random()*10)::integer)),
			(select repeat(substring('абвгдеёжзийклмнопрстуфхцчшщьыъэюя',1,(random()*33)::integer),(random()*10)::integer)),
			(select id from account order by random () limit 1), 
			(select id from contact order by random () limit 1), 
			(select repeat(substring('абвгдеёжзийклмнопрстуфхцчшщьыъэюя',1,(random()*33)::integer),(random()*10)::integer)),
			(select id from "user" order by random () limit 1),
			(select * from unnest(enum_range(null::status_list)) order by random() limit 1),
			(select now() - interval '1 day' * round(random() * 1000)));
		end loop;
	end;
$$ language plpgsql;

--7 задание --  удаление тестовых данных

create or replace procedure erase_test_data () as $$
	begin 
		delete from courier;
		delete from contact;
		delete from account;
		delete from "user";
	end;
$$ language plpgsql;

--8 задание -- добавление новой записи о заявке на курьера

create procedure add_courier(fr_place varchar(250), wh_place varchar(250), name varchar(100), 
ac_id uuid, con_id uuid, descrip text, us_id uuid) as $$
	begin 
		insert into courier (from_place, where_place, name, account_id, contact_id, description, user_id)
		values (fr_place, wh_place, name, ac_id, con_id, descrip, us_id);
	end;
$$ language plpgsql;

--9 задание -- получение записей о заявках на курьера

create or replace function get_courier() 
returns table (id uuid, from_place varchar, where_place varchar, name varchar, account_id uuid, account varchar,
contact_id uuid, contact varchar, description text, user_id uuid, "user" varchar, status status_list, created_date date) as $$
	begin   
		return query
			select co.id, co.from_place, co.where_place, co.name, a.id as account_id, a.name as account, c.id as contact_id, 
			concat_ws(c.last_name, ' ', c.first_name)::varchar as contact, co.description, u.id as user_id, 
			concat_ws(u.last_name, ' ', u.first_name)::varchar as "user", co.status, co.created_date
			from courier co
			join account a on co.account_id = a.id
			join contact c on co.contact_id = c.id 
			join "user" u on co.user_id = u.id	
			order by co.status, co.created_date desc;
	end;
$$ language plpgsql;

--10 задание -- изменение статуса заявки

create or replace procedure change_status (status_1 status_list, id_1 uuid) as $$
	begin 
		update status 
		set status = status_1
		where id = id_1;
	end;
$$ language plpgsql;

--11 задание -- получение списка сотрудников компании
 
create or replace function get_users()
returns table ("user" varchar) as $$
	begin  
		return query
			select concat_ws(last_name, ' ', first_name)::varchar as user 
			from "user"
			where dismissed = false
			order by user;
	end;
$$ language plpgsql;

--12 задание -- получение списка контрагентов компании

create or replace function get_accounts()
returns table (account varchar) as $$
	begin
		return query
			select name 
			from account 
			order by name;
	end;
$$ language plpgsql;

--13 задание -- получение списка контактов

create or replace function get_contacts (acc_id uuid)
returns table (contact varchar) as $$
	begin
		if acc_id is null then 
		return query select 'Выберите контрагента'::varchar;
		else
		return query
			select concat_ws(last_name, ' ', first_name)::varchar
			from contact c
			where account_id = acc_id
			order by contact;
		end if;
	end;
$$ language plpgsql;

--14 задание -- статистика о заявках на курьера

create view courier_statistic as
select id as account_id, name as account, count_courier, count_complete, count_canceled, percent_relative_prev_month,
count_where_place, count_contact, cansel_user_array
from account a
join (
	select account_id, count(id) count_courier, count(where_place) count_where_place, count(id) count_contact
	from courier
	group by account_id) t on a.id = t.account_id
join (
	select count(id) count_complete, account_id
	from courier
	group by account_id, status
	having status = 'Выполнено') t2 on t2.account_id = a.id
join (
	select count(id) count_canceled, account_id
	from courier
	group by account_id, status
	having status = 'Отменен') t3 on t3.account_id = a.id
join (
	select coalesce(100 * (count_month / lag (count_month) over (partition by account_id order by "month" )), '0') percent_relative_prev_month , account_id,"month"
from (
	select count(id) count_month, date_part('month', created_date) "month", account_id
	from courier c
	group by date_part('month', created_date), account_id
	order by date_part('month', created_date)) t) t4 on t4.account_id = a.id
join (
		select array[user_id] cansel_user_array, account_id
		from courier 
		where status = 'Отменен') t5 on t5.account_id = a.id