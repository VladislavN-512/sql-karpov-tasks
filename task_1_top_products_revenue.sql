with t1 as (SELECT p.name,
                   sum(p.price) as summa
            FROM   (SELECT order_id,
                           unnest(product_ids) as product_id
                    FROM   orders
                    WHERE  order_id not in (SELECT order_id
                                            FROM   user_actions
                                            WHERE  action = 'cancel_order')
                    GROUP BY order_id, product_ids) tt1 join products p using (product_id)
            GROUP BY 1), 
  t2 as (SELECT name as product_name, sum(t1.summa) as revenue
         FROM   t1
         GROUP BY name), 
  t3 as (SELECT sum(revenue) as total
         FROM   t2), 
  with_shares as (SELECT product_name, revenue, 
                    round(revenue::numeric / t3.total * 100, 2) as rounded_share
                  FROM   t2, t3)
SELECT case 
          when rounded_share < 0.5 then 'ДРУГОЕ'
          else product_name 
        end as product_name,
       sum(revenue) as revenue,
       sum(rounded_share) as share_in_revenue
FROM   with_shares
GROUP BY 1
ORDER BY 2 desc
