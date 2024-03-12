------------------------------CASE 4------------------------------------


--Soru 1: Ödeme yaparken taksit sayısı fazla olan kullanıcılar en çok hangi bölgede yaşamaktadır? Bu çıktıyı yorumlayınız.

--Taksit sayısı ve bölgelere göre ayrılmış çözümü
SELECT  customer_city, payment_installments,
		COUNT(DISTINCT customer_unique_id) AS customer_count
		FROM  payments 
		INNER JOIN   orders USING(order_id) 
		INNER JOIN    customers USING(customer_id)
		WHERE    payment_installments > 2
		GROUP BY   customer_city, payment_installments
		HAVING  COUNT(DISTINCT customer_unique_id) > 5
		ORDER BY 3,2 DESC;

--CTE ile bölge bazlı çözümü 
	WITH CustomerCounts AS (
		SELECT  customer_city, customer_state,
				COUNT(DISTINCT customer_unique_id) AS customer_count
		FROM payments 
		INNER JOIN orders USING(order_id) 
		INNER JOIN customers USING(customer_id)
		WHERE payment_type = 'credit_card' AND payment_installments > 2
		GROUP BY customer_city,customer_state
)
SELECT  customer_state,customer_city,
		customer_count
FROM CustomerCounts
WHERE customer_count > 1
ORDER BY customer_count DESC;


------------------------------

--Soru 2: Ödeme tipine göre başarılı order sayısı ve toplam başarılı ödeme tutarını hesaplayınız. En çok kullanılan ödeme tipinden en az olana göre sıralayınız.
SELECT  DISTINCT payment_type,
		COUNT( order_id) OVER(partition by payment_type) as delivered_orderCount,
		ROUND(SUM(payment_value) OVER(partition by payment_type)) || ' BRL' as total_payment
		FROM orders 
		INNER JOIN payments USING(order_id)
		WHERE order_Status = 'delivered'
ORDER BY
    delivered_orderCount DESC;


------------------------------

--Soru 3: Tek çekimde ve taksitle ödenen siparişlerin kategori bazlı analizini yapınız. En çok hangi kategorilerde taksitle ödeme kullanılmaktadır?

--Taksitli ödeme tablosu:
WITH categorization AS (
	SELECT 	
		CASE WHEN category_name_english IS NULL THEN 'UNCATEGORIZED' ELSE category_name_english END,
		COUNT(DISTINCT o.order_id) as installment_order
		FROM orders O
		LEFT JOIN payments p USING(ORDER_ID)
		LEFT JOIN order_items oi USING(ORDER_ID)
		LEFT JOIN products pr USING(PRODUCT_ID)
		INNER JOIN translation t ON pr.product_category_name = t.category_name
		WHERE payment_installments > 1 AND payment_type = 'credit_card'
		GROUP BY 1
		order by 2 desc
),
--Tek çekim ödeme tablosu
categorization1 AS (	
		SELECT 	
		CASE WHEN category_name_english IS NULL THEN 'UNCATEGORIZED' ELSE category_name_english END,
		COUNT(DISTINCT o.order_id) as single_payment_order
		FROM orders o
		LEFT JOIN payments p USING(ORDER_ID)
		LEFT JOIN order_items oi USING(ORDER_ID)
		LEFT JOIN products pr USING(PRODUCT_ID)
		INNER JOIN translation t ON pr.product_category_name= t.category_name
		WHERE payment_installments  = 1 --AND payment_type = 'credit_card'
		GROUP BY 1
		ORDER BY 2 DESC
)
SELECT * FROM categorization1
JOIN categorization USING(category_name_english)