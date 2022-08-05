
create table fact_flights (
passenger_name varchar(250),
scheduled_departure timestamptz,
scheduled_arrival timestamptz,
actual_departure timestamptz,
actual_arrival timestamptz,
departure_delay int,
arrival_delay int,
aircraft_code varchar(100),
departure_airport varchar(100),
arrival_airport varchar(100),
fare_conditions varchar(100),
amount numeric(10,2));

create table dim.calendar (
date date); 

insert into dim.calendar (date)
values (generate_series ('01.01.2017', '31.12.2027', interval '1 day'));

create table dim.passengers (
passenger_id varchar(30),
passenger_name text,
contact_data varchar(300));

create table dim.aircrafts (
aircraft_code varchar(30),
model text,
range varchar(300));

create table dim.airports (
airport_code bpchar(3),
airport_name text,
city text,
timezone text);

create table dim.tariff (
ticket_no bpchar(13),
flight_id int4,
fare_conditions varchar(10),
amount numeric(10,2));