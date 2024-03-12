------------------------------CASE 5------------------------------------

--Aşağıdaki e_commerce_data_.csv doyasındaki veri setini kullanarak RFM analizi yapınız. 
 --"2011-12-09"
 
WITH rfm_fixed AS (
  	SELECT   customer_id,
             invoiceno,
             quantity,
             invoicedate,
             unitprice
             FROM rfm
             WHERE customer_id IS NOT NULL AND 
		     invoiceno IS NOT NULL AND invoiceno NOT LIKE 'C%'
             AND quantity > 0 
             AND unitprice > 0
),
date AS (
	SELECT customer_id, 
	MAX(invoicedate)  as max_date
		FROM rfm_fixed 
			GROUP BY 1
),
recency AS (
 SELECT customer_id, 
		max_date,
		('2011-12-09' - max_date::DATE) as recency
			FROM date
),
frequency AS (
		SELECT customer_id, 
			COUNT(distinct invoiceno) as frequency
			FROM rfm_fixed 
		GROUP BY 1
),
monetary AS (
		SELECT customer_id,
		ROUND(SUM(quantity * unitprice)::numeric, 2) AS monetary		
		FROM rfm_fixed 
		GROUP BY customer_id
),
scores AS (
	SELECT  customer_id,
			r.recency,
			NTILE(5) OVER(ORDER BY recency DESC) AS recency_score,
			f.frequency,
			NTILE(5) OVER(ORDER BY frequency) AS frequency_score,
			m.monetary,
			NTILE(5) OVER(ORDER BY monetary) AS monetary_score
			FROM recency r 
			LEFT JOIN frequency f USING(customer_id)
			LEFT JOIN monetary m USING(customer_id)
),
merge_table_monfre AS (
		SELECT  customer_id,
				recency_score,
				(frequency_score + monetary_score) as monefreq_score
				FROM scores
),
rfm_Score AS (
		SELECT customer_id, recency_score, 
		ntile(5) OVER (ORDER BY monefreq_score) as mone_fre_score
		FROM merge_table_monfre
),
rfm_segmentation AS (		
	 SELECT  customer_id,
       		 recency_score,
       		 mone_fre_score,
    CASE WHEN recency_score >= 4 AND mone_fre_score = 5 THEN 'Diamond Customers'
	 	 WHEN recency_score >= 4 AND mone_fre_score >= 3 THEN 'Loyal Customers'
		 WHEN recency_score > 3 AND mone_fre_score <= 4 THEN 'New Customers'
		 WHEN recency_score = 3 AND mone_fre_score >= 4 THEN 'At Risk Customers'
		 WHEN (recency_score <= 3 AND recency_score > 1)  AND mone_fre_score <= 3 THEN 'Dormant Customers'
		 WHEN recency_score <= 2 AND (mone_fre_score >= 1 AND mone_fre_score <= 3) THEN 'Lost Customers'
    	 ELSE 'Need to Be Regained'
END AS segment
	FROM rfm_Score
)
	SELECT  segment,
			COUNT(DISTINCT customer_id) AS customer_count
			FROM rfm_segmentation 
			GROUP BY segment 
			ORDER BY 2 DESC;