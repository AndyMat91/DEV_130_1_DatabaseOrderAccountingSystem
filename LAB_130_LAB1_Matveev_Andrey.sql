drop database if exists order_accounting_system;
create database if not exists order_accounting_system default character set utf8mb4;

create table if not exists order_accounting_system.products (
	article_number varchar(100) not null primary key,
    name varchar(50) not null,
    colour varchar(20),
    price integer check (price > 0),
    stock_balance integer check (stock_balance >= 0),
    constraint article_number_length check (length(article_number) = 7)
);


create table if not exists order_accounting_system.orders (
id integer not null primary key,
date_of_creation date not null,
customer_full_name varchar(100) not null,
contact_phone_number varchar(50),
email_address varchar(50),
delivery_address varchar(200) not null,
delivery_status char(1) default 'P' check(delivery_status in ('P', 'S', 'C')),
date_shipment_order date,
constraint date_shipment_order_status check(delivery_status ='S' AND date_shipment_order is not null OR delivery_status !='S' AND date_shipment_order is null)
);


create table if not exists order_accounting_system.order_positions (
order_entry_code integer not null,
item_number varchar(100) not null check (length(item_number) = 7),
price integer check (price > 0),
quantity integer check (quantity > 0),
foreign key fk_order_positions_orders (order_entry_code) references orders(id),
foreign key fk_order_positions_products (item_number) references products(article_number),
PRIMARY KEY (item_number, order_entry_code)
);

insert into order_accounting_system.products values 
('3251615', 'Стол кухонный', 'белый', 8000, 12), 
('3251616', 'Стол кухонный', '', 8000, 15),
('3251617', 'Стул столовый "гусарский"', 'орех', 4000, 10),    -- в условии остаток на складе 0, но для проверки запроса уменьшающего остаток товара на складе, пришлось увеличить до 10
('3251619', 'Стул столовый с высокой спинкой', 'белый', 3500, 37), 
('3251620', 'Стул столовый с высокой спинкой', 'коричневый', 3500, 52);

 insert into order_accounting_system.orders values
 (1, '2020-11-20', 'Сергей Иванов', '(981)123-45-67', '', 'ул. Веденеева, 20-1-41', 'S', '2020-11-29'),
 (2, '2020-11-22', 'Алексей Комаров', '(921)001-22-33', '', 'пр. Пархоменко 51-2-123', 'S', '2020-11-29'),
 (3, '2020-11-28', 'Ирина Викторова', '(911)009-88-77', '', 'Тихорецкий пр. 21-21', 'P', null),
 (4, '2020-12-03', 'Павел Николаев','', 'pasha_nick@mail.ru', 'ул. Хлопина 3-88', 'P', null),
 (5, '2020-12-03', 'Антонина Васильева', '(931)777-66-55', 'antvas66@gmail.com', 'пр. Науки, 11-3-9', 'P', null),
 (6, '2020-12-10', 'Ирина Викторова', '(911)009-88-77', '', 'Тихорецкий пр. 21-21', 'P', null);
 
 insert into order_accounting_system.order_positions values
 (1, '3251616', 7500, 1),
 (2, '3251615', 7500, 1),
 (3, '3251615', 8000, 1),
 (3, '3251617', 4000, 4),
 (4, '3251619', 3500, 2),
 (5, '3251615', 8000, 1),
 (5, '3251617', 4000, 4),
 (6, '3251617', 4000, 2);
 
 
 -- 1). список заказов, созданных: в ноябре, в декабре;
 -- Первый закомментированный вариант также рабочий, только он не учитывает ГОД.
-- select * from order_accounting_system.orders where month (date_of_creation) = 11 OR month (date_of_creation) = 12;
select * from order_accounting_system.orders where date_of_creation >= '2020-11-01' and date_of_creation <= '2020-12-31';
 
-- 2). список заказов, отгруженных: в ноябре, в декабре;
 select * from order_accounting_system.orders where date_shipment_order >= '2020-11-01' and date_shipment_order <= '2020-12-31';

-- 3). список клиентов: для каждого клиента должны быть выведены его ФИО, телефон и адрес электронной почты;
select customer_full_name, contact_phone_number, email_address from order_accounting_system.orders;

-- 4). список позиций заказа с id=3;
select * from order_accounting_system.order_positions where order_entry_code = 3;

-- 5). названия товаров, включённых в заказ с id=3;
select name from order_accounting_system.products left join order_accounting_system.order_positions
on order_accounting_system.products.article_number = order_accounting_system.order_positions.item_number
where order_accounting_system.order_positions.order_entry_code = 3;

/* 6). Напишите запрос, фиксирующий отгрузку заказа с id=5. Запрос должен: 
• менять статус заказа и фиксировать дату отгрузки;
• уменьшать остаток товара на складе. */

update order_accounting_system.orders set delivery_status = 'S', date_shipment_order = date(now()) where id = 5;

update order_accounting_system.products
inner join order_accounting_system.order_positions
on order_accounting_system.products.article_number = order_accounting_system.order_positions.item_number
set stock_balance = (stock_balance - order_accounting_system.order_positions.quantity)
where order_accounting_system.order_positions.order_entry_code = 5; 

select * from order_accounting_system.orders;
select * from order_accounting_system.products;

/* 7). *Напишите SQL-запросы, возвращающие следующие данные:
• список отгруженных заказов, и количество позиций в каждом из них;
*/

select id, date_of_creation, customer_full_name, contact_phone_number, email_address, 
delivery_address, delivery_status, date_shipment_order, quantity
from order_accounting_system.orders as ord
inner join order_accounting_system.order_positions as ord_pos
on ord.id = ord_pos.order_entry_code
where ord.delivery_status = 'S';

-- • доработайте запрос из предыдущего пункта, чтобы он дополнительно вычислял общую стоимость заказа. 

select id, date_of_creation, customer_full_name, contact_phone_number, email_address, 
delivery_address, delivery_status, date_shipment_order, quantity, price, (price*quantity) as order_total_cost 
from order_accounting_system.orders as ord
inner join order_accounting_system.order_positions as ord_pos
on ord.id = ord_pos.order_entry_code
where ord.delivery_status = 'S';