SELECT 
    ci.city,
    COUNT(CASE WHEN c.active = 1 THEN 1 END) AS active_customers,
    COUNT(CASE WHEN c.active = 0 THEN 1 END) AS inactive_customers
FROM customer c
JOIN address a ON c.address_id = a.address_id
JOIN city ci ON a.city_id = ci.city_id
GROUP BY ci.city_id, ci.city
ORDER BY inactive_customers DESC;