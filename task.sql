-- 1 Output the number of movies in each category, sorted descending
-- Убрала лишний JOIN таблицы film, в подсчете поставила * вместо title

SELECT  category.name, COUNT(*) AS number_of_movies
FROM film_category
INNER JOIN category ON film_category.category_id = category.category_id
GROUP BY category.name
ORDER BY number_of_movies DESC;
 
-- 2 Output the 10 actors whose movies rented the most, sorted in descending order

SELECT actor.actor_id AS actor_number, COUNT(rental.rental_id)
FROM actor
INNER JOIN film_actor ON actor.actor_id = film_actor.actor_id
INNER JOIN film ON film_actor.film_id = film.film_id
INNER JOIN inventory ON film.film_id = inventory.film_id
INNER JOIN rental ON inventory.inventory_id = rental.inventory_id
GROUP BY actor.actor_id
ORDER BY COUNT(rental.rental_id) DESC
LIMIT 10;

-- 3 Output the category of movies on which the most money was spent.

SELECT category.name, SUM(payment.amount)
FROM category
INNER JOIN film_category ON category.category_id = film_category.category_id
INNER JOIN inventory ON film.film_id = inventory.film_id
INNER JOIN rental ON inventory.inventory_id = rental.inventory_id
INNER JOIN payment ON rental.rental_id = payment.rental_id
GROUP BY category.name
ORDER BY SUM(payment.amount) DESC
LIMIT 1;

-- 4 Print the names of movies that are not in the inventory. 
-- Write a query without using the IN operator.

SELECT film.title
FROM film
EXCEPT
SELECT film.title
FROM film
INNER JOIN inventory ON film.film_id = inventory.film_id
WHERE film.film_id = inventory.film_id;

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
	GROUP BY actor.actor_id, first_name, last_name
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

-- 7 Output the category of movies that has the highest number of total rental hours in the city 
-- (customer.address_id in this city) and that start with the letter “a”. 
-- Do the same for cities that have a “-” in them. Write everything in one query.

SELECT city, name, total_duration
FROM
(
SELECT city.city, 
	category.name, 
	SUM(film.rental_duration) AS total_duration,
	RANK() OVER(PARTITION BY city.city ORDER BY SUM(film.rental_duration) DESC) AS rnk
FROM city
INNER JOIN address USING(city_id)
INNER JOIN store USING (address_id)
INNER JOIN inventory USING (store_id)
INNER JOIN rental USING (inventory_id)
INNER JOIN film USING (film_id)
INNER JOIN film_category USING (film_id)
INNER JOIN category USING (category_id)
WHERE city.city LIKE 'A%' OR city.city LIKE '%-%'
GROUP BY city.city, category.name
) c
WHERE rnk = 1;
