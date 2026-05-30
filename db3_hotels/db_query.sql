/*
 Задача 1
 Определить, какие клиенты сделали более двух бронирований в разных отелях, и вывести информацию о каждом таком клиенте,
 включая его имя, электронную почту, телефон, общее количество бронирований, а также список отелей,
 в которых они бронировали номера (объединенные в одно поле через запятую).
 Также подсчитать среднюю длительность их пребывания (в днях) по всем бронированиям.
 Отсортировать результаты по количеству бронирований в порядке убывания.
 */

WITH customer_booking_details AS (
    -- Для каждого клиента собираем агрегированную информацию по бронированиям
    SELECT
        c.ID_customer,
        c.name,
        c.email,
        c.phone,
        COUNT(b.ID_booking) AS total_bookings,
        COUNT(DISTINCT h.ID_hotel) AS unique_hotels,
        AVG(b.check_out_date - b.check_in_date) AS avg_stay_duration,
        STRING_AGG(DISTINCT h.name, ', ' ORDER BY h.name) AS hotels_list
    FROM Customer c
    JOIN Booking b ON c.ID_customer = b.ID_customer
    JOIN Room r ON b.ID_room = r.ID_room
    JOIN Hotel h ON r.ID_hotel = h.ID_hotel
    GROUP BY c.ID_customer, c.name, c.email, c.phone
)
-- Отбираем клиентов, которые сделали более двух бронирований в разных отелях
SELECT
    name,
    email,
    phone,
    total_bookings,
    hotels_list,
    ROUND(avg_stay_duration, 4) AS avg_stay_duration
FROM customer_booking_details
WHERE total_bookings > 2
  AND unique_hotels > 1
ORDER BY total_bookings DESC;

/*
 Задача 2
 Необходимо провести анализ клиентов, которые сделали более двух бронирований в разных отелях
 и потратили более 500 долларов на свои бронирования.
 Для этого:

 Определить клиентов, которые сделали более двух бронирований и забронировали номера в более чем одном отеле.
 Вывести для каждого такого клиента следующие данные: ID_customer, имя, общее количество бронирований,
 общее количество уникальных отелей, в которых они бронировали номера, и общую сумму, потраченную на бронирования.

 Также определить клиентов, которые потратили более 500 долларов на бронирования, и вывести для них ID_customer,
 имя, общую сумму, потраченную на бронирования, и общее количество бронирований.

 В результате объединить данные из первых двух пунктов, чтобы получить список клиентов,
 которые соответствуют условиям обоих запросов. Отобразить поля: ID_customer, имя, общее количество бронирований,
 общую сумму, потраченную на бронирования, и общее количество уникальных отелей.

 Результаты отсортировать по общей сумме, потраченной клиентами, в порядке возрастания.
 */

SELECT
	c.ID_customer,
	c.name,
	COUNT(*) AS total_bookings,
	ROUND(SUM(r.price), 2) AS total_spent,
	COUNT(DISTINCT h.ID_hotel) AS unique_hotels
FROM
	Customer c
JOIN Booking b ON
	c.ID_customer = b.ID_customer
JOIN Room r ON
	b.ID_room = r.ID_room
JOIN Hotel h ON
	r.ID_hotel = h.ID_hotel
GROUP BY
	c.ID_customer,
	c.name
HAVING
	COUNT(*) > 2
	AND COUNT(DISTINCT h.ID_hotel) > 1
	AND SUM(r.price) > 500
ORDER BY
	total_spent ASC;

/*
 Задача 3
 Вам необходимо провести анализ данных о бронированиях в отелях и определить предпочтения клиентов по типу отелей.
 Для этого выполните следующие шаги:

 1. Категоризация отелей.
 Определите категорию каждого отеля на основе средней стоимости номера:
 «Дешевый»: средняя стоимость менее 175 долларов.
 «Средний»: средняя стоимость от 175 до 300 долларов.
 «Дорогой»: средняя стоимость более 300 долларов.

 2. Анализ предпочтений клиентов.
 Для каждого клиента определите предпочитаемый тип отеля на основании условия ниже:
 Если у клиента есть хотя бы один «дорогой» отель, присвойте ему категорию «дорогой».
 Если у клиента нет «дорогих» отелей, но есть хотя бы один «средний», присвойте ему категорию «средний».
 Если у клиента нет «дорогих» и «средних» отелей, но есть «дешевые», присвойте ему категорию предпочитаемых
 отелей «дешевый».

 3. Вывод информации.
 Выведите для каждого клиента следующую информацию:
 ID_customer: уникальный идентификатор клиента.
 name: имя клиента.
 preferred_hotel_type: предпочитаемый тип отеля.
 visited_hotels: список уникальных отелей, которые посетил клиент.

 4. Сортировка результатов.
 Отсортируйте клиентов так, чтобы сначала шли клиенты с «дешевыми» отелями, затем со «средними» и в конце — с «дорогими».
 */

WITH hotel_categories AS (
    -- Определяем категорию каждого отеля на основе средней стоимости номера
    SELECT
        h.ID_hotel,
        h.name AS hotel_name,
        AVG(r.price) AS avg_price,
        CASE
            WHEN AVG(r.price) < 175 THEN 'Дешевый'
            WHEN AVG(r.price) BETWEEN 175 AND 300 THEN 'Средний'
            ELSE 'Дорогой'
        END AS hotel_category
    FROM Hotel h
    JOIN Room r ON h.ID_hotel = r.ID_hotel
    GROUP BY h.ID_hotel, h.name
),
customer_hotels AS (
    -- Для каждого клиента собираем информацию о посещенных отелях и их категориях
    SELECT DISTINCT
        c.ID_customer,
        c.name,
        hc.hotel_name,
        hc.hotel_category
    FROM Customer c
    JOIN Booking b ON c.ID_customer = b.ID_customer
    JOIN Room r ON b.ID_room = r.ID_room
    JOIN hotel_categories hc ON r.ID_hotel = hc.ID_hotel
),
customer_category AS (
    -- Определяем предпочитаемую категорию для каждого клиента по правилам приоритета
    SELECT
        ID_customer,
        name,
        CASE
            -- Если есть хотя бы один "Дорогой" отель
            WHEN COUNT(CASE WHEN hotel_category = 'Дорогой' THEN 1 END) > 0 THEN 'Дорогой'
            -- Если нет "Дорогих", но есть хотя бы один "Средний"
            WHEN COUNT(CASE WHEN hotel_category = 'Средний' THEN 1 END) > 0 THEN 'Средний'
            -- Если только "Дешевые" отели
            ELSE 'Дешевый'
        END AS preferred_hotel_type
    FROM customer_hotels
    GROUP BY ID_customer, name
),
customer_hotels_list AS (
    -- Формируем список уникальных отелей для каждого клиента
    SELECT
        ID_customer,
        STRING_AGG(DISTINCT hotel_name, ', ' ORDER BY hotel_name) AS visited_hotels
    FROM customer_hotels
    GROUP BY ID_customer
)
-- Объединяем данные и сортируем по категории (Дешевый → Средний → Дорогой)
SELECT
    cc.ID_customer,
    cc.name,
    cc.preferred_hotel_type,
    chl.visited_hotels
FROM customer_category cc
JOIN customer_hotels_list chl ON cc.ID_customer = chl.ID_customer
ORDER BY
    CASE cc.preferred_hotel_type
        WHEN 'Дешевый' THEN 1
        WHEN 'Средний' THEN 2
        WHEN 'Дорогой' THEN 3
    END;
