------------------------------CASE 2------------------------------------

--Soru 1: Hangi şehirlerdeki müşteriler daha çok alışveriş yapıyor? Müşterinin şehrini en çok sipariş verdiği şehir olarak belirleyip analizi ona göre yapınız. 

WITH order_table AS (
		SELECT customer_unique_id,
				customer_city,
		COUNT(DISTINCT order_id) as order_Count
		FROM orders o JOIN customers c USING(customer_id) 
		GROUP BY 1,2
	),
city_table AS (
		SELECT *, 
		ROW_NUMBER() OVER (PARTITION BY customer_unique_id ORDER BY order_count DESC) city_no
		FROM order_table
)
		SELECT customer_city,
		COUNT(customer_unique_id) as totalCustomer
		FROM city_table
			WHERE city_no = 1
			GROUP BY 1
			ORDER BY 2 DESC