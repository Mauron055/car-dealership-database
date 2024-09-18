CREATE SCHEMA raw_data;

CREATE TABLE raw_data.sales
(
	id SMALLINT PRIMARY KEY,
	auto VARCHAR(50),
	gasoline_consumption VARCHAR(50),
	price VARCHAR(50),
	date VARCHAR(50),
	person VARCHAR(50),
	phone VARCHAR (50),
	discount VARCHAR(50),
	brand_origin VARCHAR(50)	
);
COPY raw_data.sales(id, auto, gasoline_consumption, price, date, person, phone, discount, brand_origin)
FROM 'E:\Chrome Downloads\cars.csv' CSV HEADER NULL 'null';
CREATE SCHEMA car_shop;
CREATE TABLE car_shop.clients
(
	id SERIAL PRIMARY KEY,
	name VARCHAR(50) NOT NULL, --имя клиента не будет превышать 50 символов
	phone VARCHAR(50) UNIQUE --телефон клиента не будет превышать 50 символов и может содержать симмволы + или ()
);
CREATE TABLE car_shop.cars
(
	id SERIAL PRIMARY KEY,
	brand VARCHAR(50) NOT NULL, --название бренда не будет превышать 50 символов
	name VARCHAR(50) NOT NULL, --название авто не будет превышать 50 символов
	brand_origin VARCHAR(50), --страна не будет превышать 50 символов
	gas_consumption NUMERIC(5,2) -- цена может содержать только сотые и не может быть больше 3значной суммы.
);
CREATE TABLE car_shop.colours
(
	id SERIAL PRIMARY KEY,
	colour VARCHAR(50) NOT NULL --название цвета не будет превышать 50 символов
);
CREATE TABLE car_shop.purchases
(
	id SERIAL PRIMARY KEY,
	client SMALLINT REFERENCES car_shop.clients, --id клиента
	car SMALLINT REFERENCES car_shop.cars,--id автомобиля
	colour SMALLINT REFERENCES car_shop.colours,--id цвета
	date DATE NOT NULL,-- дата покупки
	discount INT NOT NULL,-- скидка
	price NUMERIC(9,2) NOT NULL--цена со скидкой, тип numeric тк больше 7значных чисел нет
);
INSERT INTO car_shop.clients (name, phone)
SELECT DISTINCT person, phone
FROM raw_data.sales;
INSERT INTO car_shop.colours (colour)
SELECT DISTINCT (SPLIT_PART(auto, ',','2'))
FROM raw_data.sales;
INSERT INTO car_shop.cars (brand, name, brand_origin, gas_consumption)
SELECT DISTINCT (SPLIT_PART(auto, ' ','1')), 
TRIM(REPLACE(REPLACE(auto,SPLIT_PART(auto, ',','2'),''),SPLIT_PART(auto, ' ','1'), ' '),' ,'),
brand_origin,
CASE WHEN gasoline_consumption IS NULL THEN 0
ELSE gasoline_consumption::numeric(5,2)
END
FROM raw_data.sales;
 
INSERT INTO car_shop.purchases (client, car, colour, date, discount, price)
SELECT c.id, ca.id, cc.id, s.date::date, s.discount::int, s.price::numeric(9,2)
FROM raw_data.sales s
JOIN car_shop.clients c ON s.person = c.name
JOIN car_shop.cars ca ON SPLIT_PART(s.auto,',',1) = CONCAT(ca.brand, ' ', ca.name)
JOIN car_shop.colours cc ON SPLIT_PART(s.auto,',',2) = cc.colour;

SELECT (COUNT(CASE WHEN gasoline_consumption IS NULL THEN 1 END)::float / COUNT(*)) * 100 AS percentage
FROM raw_data.sales;

SELECT c.brand, EXTRACT(YEAR FROM p.date) AS purchase_year, ROUND(AVG(p.price), 2) AS average_price
FROM car_shop.cars c
JOIN car_shop.purchases p ON c.id = p.car
GROUP BY c.brand, purchase_year
ORDER BY c.brand, purchase_year;
 
SELECT EXTRACT(MONTH FROM p.date) AS month, EXTRACT(YEAR FROM p.date) AS year, ROUND(AVG(p.price), 2) AS average_price
FROM car_shop.cars c
JOIN car_shop.purchases p ON c.id = p.car
GROUP BY EXTRACT(MONTH FROM p.date), EXTRACT(YEAR FROM p.date)
HAVING EXTRACT(YEAR FROM p.date) = 2022
ORDER BY EXTRACT(MONTH FROM p.date);
 
SELECT cl.name, STRING_AGG(CONCAT(c.brand,' ',c.name), ', ')
FROM car_shop.purchases p
JOIN car_shop.cars c ON c.id = p.car
JOIN car_shop.clients cl ON cl.id = p.client
GROUP BY cl.name
ORDER BY cl.name;
 
SELECT c.brand_origin, MAX(p.price - p.price*(p.discount::numeric(4,2)/100))::numeric(9,2),
MIN(p.price - p.price*(p.discount::numeric(4,2)/100))::numeric(9,2)
FROM car_shop.cars c JOIN car_shop.purchases p ON p.car = c.id
GROUP BY c.brand_origin
HAVING c.brand_origin IS NOT NULL;
 
SELECT COUNT(c.phone) AS clients_from_usa
FROM car_shop.clients c
WHERE SPLIT_PART(c.phone,'-', 1) = '+1';
