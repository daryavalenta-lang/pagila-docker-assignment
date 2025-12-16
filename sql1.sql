WITH city_category_rental_hours AS (
    SELECT 
        ci.city,
        c.name AS category_name,
        SUM(EXTRACT(EPOCH FROM (r.return_date - r.rental_date))/3600) AS rental_hours
    FROM rental r
    JOIN inventory i ON r.inventory_id = i.inventory_id
    JOIN film f ON i.film_id = f.film_id
    JOIN film_category fc ON f.film_id = fc.film_id
    JOIN category c ON fc.category_id = c.category_id
    JOIN customer cust ON r.customer_id = cust.customer_id
    JOIN address a ON cust.address_id = a.address_id
    JOIN city ci ON a.city_id = ci.city_id
    WHERE r.return_date IS NOT NULL
    GROUP BY ci.city, c.name
),
max_category_per_city AS (
    SELECT 
        city,
        category_name,
        rental_hours,
        ROW_NUMBER() OVER (PARTITION BY city ORDER BY rental_hours DESC) AS rn
    FROM city_category_rental_hours
)
SELECT 
    'Cities starting with A' AS city_type,
    mcp.city,
    mcp.category_name,
    mcp.rental_hours
FROM max_category_per_city mcp
WHERE mcp.rn = 1 
  AND mcp.city LIKE 'A%'

UNION ALL

SELECT 
    'Cities with hyphen' AS city_type,
    mcp.city,
    mcp.category_name,
    mcp.rental_hours
FROM max_category_per_city mcp
WHERE mcp.rn = 1 
  AND mcp.city LIKE '%-%'
ORDER BY city_type, rental_hours DESC;