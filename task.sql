-- 1 Output the number of movies in each category, sorted descending

SELECT  category.name, COUNT(title) AS number_of_movies
FROM film
INNER JOIN film_category ON film.film_id = film_category.film_id
INNER JOIN category ON film_category.category_id = category.category_id
GROUP BY category.name
ORDER BY number_of_movies DESC;
 
-- 2 Output the 10 actors whose movies rented the most, sorted in descending order.
-- ВЫБРАТЬ КАЖДОГО АКТЕРА, ПРОСУММИРОВАТЬ ЕГО РЕНТУ И ВЫБРАТЬ ТОП 10

SELECT (first_name, last_name) AS actor, SUM(film.rental_rate) AS summary_rent
FROM actor
INNER JOIN film_actor ON actor.actor_id = film_actor.actor_id
INNER JOIN film ON film_actor.film_id = film.film_id
GROUP BY actor
ORDER BY summary_rent DESC
LIMIT 10;

-- 3 Output the category of movies on which the most money was spent.
-- Возможно под затратами понимается replacement_cost

	SELECT DISTINCT category.name, SUM(replacement_cost) AS most_money_spent
	FROM film 
	INNER JOIN film_category ON film.film_id = film_category.film_id
	INNER JOIN category ON film_category.category_id = category.category_id
	WHERE film_category.category_id = category.category_id
	GROUP BY category.name
	ORDER BY most_money_spent DESC
	LIMIT 1;

-- 4 Print the names of movies that are not in the inventory. 
-- Write a query without using the IN operator.

SELECT film_id
FROM film
EXCEPT
SELECT film_id
FROM inventory;

-- 5 Output the top 3 actors who have appeared the most in movies in the “Children” category. 
-- If several actors have the same number of movies, output all of them.

WITH ranked AS
	(
	SELECT first_name, last_name, COUNT(film.title) AS number_of_movies, DENSE_RANK() OVER(ORDER BY COUNT(film.title) DESC) AS rnk
	FROM actor
	INNER JOIN film_actor ON actor.actor_id = film_actor.actor_id
	INNER JOIN film ON film_actor.film_id = film.film_id
	INNER JOIN film_category ON film.film_id = film_category.film_id
	INNER JOIN category ON film_category.category_id = category.category_id
	WHERE category.name = 'Children'
	GROUP BY first_name, last_name
	)

SELECT first_name, last_name, number_of_movies
FROM ranked
WHERE rnk<=3;

-- 6 Output cities with the number of active and inactive customers (active - customer.active = 1). 
-- Sort by the number of inactive customers in descending order.

SELECT city.city, (SUM(customer.active)) AS active, (COUNT(*) - SUM(customer.active)) AS inactive, COUNT(*) AS total
FROM city
INNER JOIN address ON city.city_id = address.city_id
INNER JOIN customer ON address.address_id = customer.address_id
GROUP BY city.city
ORDER BY inactive DESC;

-- 7 Output the category of movies that have the highest number of total rental hours in the city 
-- (customer.address_id in this city) and that start with the letter “a”. 
-- Do the same for cities that have a “-” in them. Write everything in one query.

WITH ranked AS(
	SELECT city.city, 
		category.name, 
		 SUM(film.rental_duration) AS total_hours,
		 DENSE_RANK() OVER (PARTITION BY city ORDER BY SUM(film.rental_duration) DESC) AS rnk
	FROM city	
	INNER JOIN address ON city.city_id = address.city_id
	INNER JOIN customer ON address.address_id = customer.address_id
	INNER JOIN store ON customer.store_id = store.store_id
	INNER JOIN inventory ON store.store_id = inventory.store_id
	INNER JOIN film ON inventory.film_id = film.film_id
	INNER JOIN film_category ON film.film_id = film_category.film_id
	INNER JOIN category ON film_category.category_id = category.category_id
	WHERE city.city LIKE 'a%' AND city.city LIKE '%-%'
	GROUP BY city, category.name
	)

SELECT ranked.city, ranked.name, ranked.total_hours
FROM ranked
WHERE rnk=1;

