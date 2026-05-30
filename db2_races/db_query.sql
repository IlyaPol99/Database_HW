/*
 Задача 1
 Определить, какие автомобили из каждого класса имеют наименьшую среднюю позицию в гонках,
 и вывести информацию о каждом таком автомобиле для данного класса, включая его класс,
 среднюю позицию и количество гонок, в которых он участвовал.
 Также отсортировать результаты по средней позиции.
 */

WITH car_positions AS (
    -- Для каждого автомобиля вычисляем среднюю позицию и количество гонок
    SELECT
        c.class,
        c.name AS car_name,
        AVG(r.position) AS average_position,
        COUNT(r.race) AS race_count
    FROM
        Cars c
    JOIN
        Results r ON c.name = r.car
    GROUP BY
        c.class, c.name
),
min_avg_position AS (
    -- Для каждого класса находим минимальную среднюю позицию
    SELECT
        class,
        MIN(average_position) AS min_average_position
    FROM
        car_positions
    GROUP BY
        class
)
-- Выбираем автомобили с минимальной средней позицией в своем классе
SELECT
    cp.car_name,
    cp.class AS car_class,
    ROUND(cp.average_position, 4) AS average_position,
    cp.race_count
FROM
    car_positions cp
JOIN
    min_avg_position map ON cp.class = map.class
    AND cp.average_position = map.min_average_position
ORDER BY
    cp.average_position;

/*
 Задача 2
 Определить автомобиль, который имеет наименьшую среднюю позицию в гонках среди всех автомобилей,
 и вывести информацию об этом автомобиле, включая его класс, среднюю позицию, количество гонок,
 в которых он участвовал, и страну производства класса автомобиля.
 Если несколько автомобилей имеют одинаковую наименьшую среднюю позицию,
 выбрать один из них по алфавиту (по имени автомобиля).
 */

WITH car_positions AS (
    -- Для каждого автомобиля вычисляем среднюю позицию
    SELECT
        c.name AS car_name,
        c.class AS car_class,
        cl.country AS car_country,
        AVG(r.position) AS average_position,
        COUNT(r.race) AS race_count
    FROM
        Cars c
    JOIN
        Results r ON c.name = r.car
    JOIN
        Classes cl ON c.class = cl.class
    GROUP BY
        c.name, c.class, cl.country
)
-- Выбираем автомобиль с минимальной средней позицией
SELECT
    car_name,
    car_class,
    ROUND(average_position, 4) AS average_position,
    race_count,
    car_country
FROM
    car_positions
WHERE
    average_position = (SELECT MIN(average_position) FROM car_positions)
ORDER BY
    car_name
LIMIT 1;

/*
 Задача 3
 Определить классы автомобилей, которые имеют наименьшую среднюю позицию в гонках,
 и вывести информацию о каждом автомобиле из этих классов, включая его имя, среднюю позицию, количество гонок,
 в которых он участвовал, страну производства класса автомобиля, а также общее количество гонок,
 в которых участвовали автомобили этих классов.
 Если несколько классов имеют одинаковую среднюю позицию, выбрать все из них.
 */

WITH car_positions AS (
    -- Для каждого класса вычисляем среднюю позицию всех его автомобилей во всех гонках
    SELECT
        cl.class,
        cl.country as car_country,
        AVG(r.position) AS class_avg_position,
        COUNT(DISTINCT r.race) AS total_races
    FROM
        Classes cl
    JOIN
        Cars c ON cl.class = c.class
    JOIN
        Results r ON c.name = r.car
    GROUP BY
        cl.class, cl.country
),
min_car_positions AS (
    -- Находим минимальную среднюю позицию среди классов
    SELECT
        MIN(class_avg_position) AS min_avg_position
    FROM
        car_positions
),
min_average_position AS (
    -- Выбираем классы с минимальной средней позицией
    SELECT
        class,
        car_country,
        total_races
    FROM
        car_positions
    WHERE
        class_avg_position = (SELECT min_avg_position FROM min_car_positions)
),
car_statistic AS (
    -- Для каждого автомобиля из выбранных классов вычисляем его статистику
    SELECT
        c.name AS car_name,
        c.class,
        AVG(r.position) AS average_position,
        COUNT(r.race) AS race_count
    FROM
        Cars c
    JOIN
        Results r ON c.name = r.car
    WHERE
        c.class IN (SELECT class FROM min_average_position)
    GROUP BY
        c.name, c.class
)
SELECT
    cs.car_name,
    cs.class AS car_class,
    ROUND(cs.average_position, 4) AS average_position,
    cs.race_count,
    map.car_country,
    map.total_races
FROM
    car_statistic cs
JOIN
    min_average_position map ON cs.class = map.class
ORDER BY
    cs.class, cs.car_name;

/*
 Задача 4
 Определить, какие автомобили имеют среднюю позицию лучше (меньше) средней позиции всех автомобилей в своем классе
 (то есть автомобилей в классе должно быть минимум два, чтобы выбрать один из них).
 Вывести информацию об этих автомобилях, включая их имя, класс, среднюю позицию, количество гонок,
 в которых они участвовали, и страну производства класса автомобиля.
 Также отсортировать результаты по классу и затем по средней позиции в порядке возрастания.
 */

 -- average_position сделал с точностью до 4 знаков после запятой, как в других задачах.
 -- В ответе примера в одной строке одна точность, а в другой другая точность.
 -- Посчитал это опечаткой.

WITH car_position AS (
    -- Для каждого автомобиля вычисляем его среднюю позицию
    SELECT
        c.name AS car_name,
        c.class AS car_class,
        cl.country AS car_country,
        AVG(r.position) AS car_avg_position,
        COUNT(r.race) AS race_count
    FROM
        Cars c
    JOIN
        Results r ON c.name = r.car
    JOIN
        Classes cl ON c.class = cl.class
    GROUP BY
        c.name, c.class, cl.country
),
total_position AS (
    -- Для каждого класса вычисляем общую среднюю позицию и количество автомобилей
    SELECT
        c.class AS car_class,
        AVG(r.position) AS class_avg_position,
        COUNT(DISTINCT c.name) AS car_count
    FROM
        Cars c
    JOIN
        Results r ON c.name = r.car
    GROUP BY
        c.class
    HAVING
        COUNT(DISTINCT c.name) >= 2  -- Только классы с минимум двумя автомобилями
)
-- Выбираем автомобили, у которых средняя позиция лучше (меньше) средней по классу
SELECT
    cp.car_name,
    cp.car_class,
    ROUND(cp.car_avg_position, 4) AS average_position,
    cp.race_count,
    cp.car_country
FROM
    car_position cp
JOIN
    total_position tp ON cp.car_class = tp.car_class
WHERE
    cp.car_avg_position < tp.class_avg_position
ORDER BY
    cp.car_class,
    cp.car_avg_position;

/*
 Задача 5
 Определить, какие классы автомобилей имеют наибольшее количество автомобилей с низкой средней позицией (больше 3.0)
 и вывести информацию о каждом автомобиле из этих классов, включая его имя, класс, среднюю позицию, количество гонок,
 в которых он участвовал, страну производства класса автомобиля, а также общее количество гонок для каждого класса.
 Отсортировать результаты по количеству автомобилей с низкой средней позицией.
 */

 -- В примере ответа в задаче 5 увидел расхождение между условием задачи и привидённым ответом
 -- В задании сказано: "с низкой средней позицией (больше 3.0)". Чтобы изменился ответ, нужно изменить это условие.

WITH car_positions AS (
    -- Для каждого автомобиля вычисляем среднюю позицию
    SELECT
        c.name AS car_name,
        c.class,
        cl.country,
        AVG(r.position) AS avg_position,
        COUNT(r.race) AS race_count
    FROM Cars c
    JOIN Results r ON c.name = r.car
    JOIN Classes cl ON c.class = cl.class
    GROUP BY c.name, c.class, cl.country
),
low_car_positions AS (
    -- Определяем автомобили с низкой средней позицией (больше 3.0)
    SELECT
        car_name,
        class,
        country,
        avg_position,
        race_count
    FROM car_positions
    WHERE avg_position > 3.0
),
bad_car_class AS (
    -- Для каждого класса считаем количество таких автомобилей
    SELECT
        class,
        COUNT(*) AS low_position_count
    FROM low_car_positions
    GROUP BY class
),
selected_classes AS (
    -- Выбираем классы с наибольшим количеством "плохих" автомобилей
    SELECT class
    FROM bad_car_class
    WHERE low_position_count = (SELECT MAX(low_position_count) AS max_count FROM bad_car_class)
),
total_races AS (
    -- Для выбранных классов считаем общее количество уникальных гонок
    SELECT
        c.class,
        COUNT(DISTINCT r.race) AS total_races
    FROM Cars c
    JOIN Results r ON c.name = r.car
    WHERE c.class IN (SELECT class FROM selected_classes)
    GROUP BY c.class
)
-- Финальный вывод
SELECT
    lcp.car_name,
    lcp.class AS car_class,
    ROUND(lcp.avg_position, 4) AS average_position,
    lcp.race_count,
    lcp.country AS car_country,
    tr.total_races,
    bcc.low_position_count
FROM low_car_positions lcp
JOIN total_races tr ON lcp.class = tr.class
JOIN bad_car_class bcc ON lcp.class = bcc.class
WHERE lcp.class IN (SELECT class FROM selected_classes)
ORDER BY
    bcc.low_position_count DESC,
    lcp.class,
    lcp.car_name;
