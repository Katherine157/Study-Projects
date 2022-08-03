
create table courier (
id uuid primary key,
from_place varchar(250) not null,
where_plact varchar(250) not null,
name varchar(100) not null,
account_id uuid references account(id),
contact_id uuid references contact(id),
description text,
user_id uuid references user(id),
status enum default 'В очереди',
created_date date);

create table account (
id uuid primary key,
name varchar(100) not null);

create table contact (
id uuid primary key,
last_name varchar(100),
first_name varchar(100) not null,
account_id uuid references account(id));

create table "user" (
id uuid primary key,
last_name varchar(100) not null,
first_name varchar(100) not null,
dismissed boolean);

create type status_list as enum
('В очереди', 'Выполняется', 'Выполнено', 'Отменен');

create role netocourier with password 'NetoSQL2022';

create user netocourier with password 'NetoSQL2022';

alter role netocourier with login;

grant connect on database postgres to "netocourier";

grant all privileges on all tables in schema public to "netocourier";

grant all privileges on all tables in schema extensions to "netocourier";
