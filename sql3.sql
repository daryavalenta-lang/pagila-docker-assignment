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