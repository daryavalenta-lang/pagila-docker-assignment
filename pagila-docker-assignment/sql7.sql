SELECT 
    c.name AS category_name,
    COUNT(*) AS movie_count
FROM film f
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
GROUP BY c.category_id, c.name
ORDER BY movie_count DESC;