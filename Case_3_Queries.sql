------------------------------CASE 3------------------------------------


--Soru 1: Siparişleri en hızlı şekilde müşterilere ulaştıran satıcılar kimlerdir? 
--Top 5 getiriniz. Bu satıcıların order sayıları ile ürünlerindeki yorumlar ve puanlamaları inceleyiniz ve yorumlayınız.

WITH order_view AS (
	SELECT  o.order_id, o.order_Status,
			oi.seller_id,
			(order_delivered_customer_date - order_approved_at) as deliveredday,
			r.review_score
		FROM orders o 
		INNER join order_items oi ON o.order_id = oi.order_id
		INNER JOIN sellers s ON oi.seller_id = s.seller_id
		INNER JOIN reviews r ON r.order_id = o.order_id
),
canceled_orders AS (
    SELECT  seller_id,
       		COALESCE(COUNT(order_id), 0) as canceled_order_count
  	 		FROM order_view
   			WHERE order_status = 'canceled'
   			GROUP BY seller_id 
)
--,temporary AS (
	SELECT 	CONCAT('Seller-',LEFT(ov.seller_id,2)) as Seller, ov.seller_id,
  	  		AVG(ov.deliveredday) AS avg_day,
  	 		ROUND(AVG(ov.review_score), 2) AS avg_score,
  	 		COUNT(ov.order_id) AS total_order,
   	 		--co.canceled_order_count,
  	 		COALESCE(CAST(co.canceled_order_count AS decimal) / NULLIF(CAST(COUNT(ov.order_id) AS decimal), 0), 0) AS canceled_order_ratio
			FROM order_view ov
    		LEFT JOIN canceled_orders co ON ov.seller_id = co.seller_id
			GROUP BY ov.seller_id,canceled_order_count
			HAVING COUNT(ov.order_id) > 20
			ORDER BY 3
			LIMIT 5
--)
--Yorumlara bakmak için yukarıdaki yorum satırlarını açıp bununla birlikte çalıştırıyoruz:
SELECT seller, seller_city, seller_state,avg_Score,total_order,canceled_order_ratio, review_score, review_comment_title, review_comment_message
FROM sellers 
inner join temporary USING(seller_id) 
inner join order_items USING(seller_id) 
inner join reviews USING(order_id)
WHERE review_comment_message IS NOT NULL
		ORDER BY avg_day
		

------------------------------

--Soru 2: Hangi satıcılar daha fazla kategoriye ait ürün satışı yapmaktadır? 

--Satıcı portföyüne göre inceleme
WITH main_table AS (
		SELECT s.seller_id,
		oi.order_id, category_name_english
		FROM order_items oi JOIN products p USING(product_id) JOIN sellers s USING(seller_id)
		JOIN translation t ON p.product_category_name = t.category_name
		WHERE product_category_name IS NOT NULL 
)
	SELECT seller_id,
			COUNT(DISTINCT category_name_english) as category,
			COUNT(distinct order_id) AS order_count
			FROM main_table
			GROUP BY 1
			ORDER BY 2 DESC
			LIMIT 30

--En çok ürün satışı yaptıkları kategorilere göre inceleme
WITH order_rows AS (
	SELECT  seller_id, category_name_english as category,
		COUNT(order_id) orderCountByCategory,
		ROW_NUMBER() OVER (partition by seller_id order by count(order_id) desc) as rn
		FROM orders left join order_items USING(ordeR_id) 
		left join products USING(product_id) 
		join translation ON translation.category_name = products.product_category_name
		GROUP BY 1,2
),
total_order AS (
	SELECT  seller_id,
			COUNT(order_id) total_order_count FROM orders left join order_items USING(ordeR_id)
			group by 1
)
SELECT  CONCAT('Seller-',seller_id) as Seller,
		category, orderCountByCategory, total_order_count
		FROM order_rows inner join total_order USING(seller_id)
		WHERE rn = 1 --AND orderCountByCategory = total_order_count
		ORDER BY 3 DESC
		