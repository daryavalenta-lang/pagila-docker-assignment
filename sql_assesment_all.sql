--------------------------Task1----------------------------
--Output the number of movies in each category, sorted descending
SELECT 
    c.name AS category_name,
    COUNT(*) AS movie_count
FROM film f
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
GROUP BY c.category_id, c.name
ORDER BY movie_count DESC;
----------------------------Task2------------------------------
--Output the 10 actors whose movies rented the most, sorted in descending order.
SELECT 
    --a.actor_id,
    a.first_name || ' ' || a.last_name AS actor_name,
    COUNT(r.rental_id) AS rental_count
FROM actor a
JOIN film_actor fa ON a.actor_id = fa.actor_id
JOIN film f ON fa.film_id = f.film_id
JOIN inventory i ON f.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
GROUP BY a.actor_id, a.first_name, a.last_name
ORDER BY rental_count DESC
LIMIT 10;
----------------------------Task3--------------------------------------
--Output the category of movies on which the most money was spent.
SELECT 
    c.name AS category_name,
    SUM(p.amount) AS total_spent
FROM payment p
JOIN rental r ON p.rental_id = r.rental_id
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
GROUP BY c.category_id, c.name
ORDER BY total_spent DESC
LIMIT 1;
----------------------------Task4----------------------------
--Print the names of movies that are not in the inventory. 
--Write a query without using the IN operator.
SELECT 
    f.title
FROM film f
LEFT JOIN inventory i ON f.film_id = i.film_id
WHERE i.inventory_id IS NULL;
--------------------------Task5--------------------------------
---Output the top 3 actors who have appeared the most in movies in the “Children” category. 
--If several actors have the same number of movies, output all of them.
WITH actor_movie_counts AS (
    SELECT 
        a.actor_id,
        a.first_name || ' ' || a.last_name AS actor_name,
        COUNT(DISTINCT f.film_id) AS movie_count,
        RANK() OVER (ORDER BY COUNT(DISTINCT f.film_id) DESC) AS rank_position
    FROM actor a
    JOIN film_actor fa ON a.actor_id = fa.actor_id
    JOIN film f ON fa.film_id = f.film_id
    JOIN film_category fc ON f.film_id = fc.film_id
    JOIN category c ON fc.category_id = c.category_id
    WHERE c.name = 'Children'
    GROUP BY a.actor_id, a.first_name, a.last_name
)
SELECT 
    actor_id,
    actor_name,
    movie_count
FROM actor_movie_counts
WHERE rank_position <= 3
ORDER BY movie_count DESC, actor_name;
--------------------------------Task6------------------- 
--Output cities with the number of active and inactive customers (active - customer.active = 1). 
--Sort by the number of inactive customers in descending order.
SELECT 
    ci.city,
    COUNT(CASE WHEN c.active = 1 THEN 1 END) AS active_customers,
    COUNT(CASE WHEN c.active = 0 THEN 1 END) AS inactive_customers
FROM customer c
JOIN address a ON c.address_id = a.address_id
JOIN city ci ON a.city_id = ci.city_id
GROUP BY ci.city_id, ci.city
ORDER BY inactive_customers DESC;
-------------------------------Task7----------------------
--Output the category of movies that have the highest number of total rental hours in the city 
--(customer.address_id in this city) and that start with the letter “a”.
--Do the same for cities that have a “-” in them. Write everything in one query.
-- Индексы для ускорения JOIN не все созданные индексы будут использоваться в запросе
CREATE INDEX idx_rental_inventory_id ON rental(inventory_id);
CREATE INDEX idx_inventory_film_id ON inventory(film_id);
CREATE INDEX idx_film_category_film_id ON film_category(film_id);
CREATE INDEX idx_customer_address_id ON customer(address_id);
CREATE INDEX idx_address_city_id ON address(city_id);


CREATE INDEX idx_city_name ON city(city);
CREATE INDEX idx_city_name_pattern ON city(city text_pattern_ops);
CREATE INDEX idx_category_id_name ON category(category_id, name);


CREATE INDEX idx_city_rental_hours ON city_category_rental_hours(city, rental_hours DESC);


CREATE INDEX idx_customer_customer_id_address_id ON customer(customer_id, address_id);


CREATE INDEX idx_rental_return_date_not_null ON rental(inventory_id) WHERE return_date IS NOT NULL;
EXPLAIN ANALYZE
WITH base_data AS (
    SELECT 
        ci.city,
        c.name AS category_name,
        SUM(
            EXTRACT(EPOCH FROM (r.return_date - r.rental_date)) / 3600.0
        ) AS rental_hours
    FROM rental r
    JOIN inventory i ON r.inventory_id = i.inventory_id
    JOIN film_category fc ON i.film_id = fc.film_id
    JOIN category c ON fc.category_id = c.category_id
    JOIN customer cust ON r.customer_id = cust.customer_id
    JOIN address a ON cust.address_id = a.address_id
    JOIN city ci ON a.city_id = ci.city_id
    WHERE r.return_date IS NOT NULL
      AND (ci.city LIKE 'A%' OR ci.city LIKE '%-%')
    GROUP BY ci.city, c.name
),
ranked AS (
    SELECT 
        city,
        category_name,
        rental_hours,
        ROW_NUMBER() OVER (PARTITION BY city ORDER BY rental_hours DESC) AS rn
    FROM base_data
)
SELECT 
    'Города на букву A' AS city_group,
    city,
    category_name AS top_category,
    ROUND(rental_hours::numeric, 2) AS total_rental_hours
FROM ranked
WHERE rn = 1 AND city LIKE 'A%'

UNION ALL

SELECT 
    'Города с дефисом' AS city_group,
    city,
    category_name AS top_category,
    ROUND(rental_hours::numeric, 2) AS total_rental_hours
FROM ranked
WHERE rn = 1 AND city LIKE '%-%'
ORDER BY city_group DESC, total_rental_hours DESC, city;