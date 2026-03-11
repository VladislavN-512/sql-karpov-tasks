-- Для каждого дня в таблицах orders и courier_actions рассчитайте следующие показатели:

-- Выручку, полученную в этот день.
-- Затраты, образовавшиеся в этот день.
-- Сумму НДС с продажи товаров в этот день.
-- Валовую прибыль в этот день (выручка за вычетом затрат и НДС).
-- Суммарную выручку на текущий день.
-- Суммарные затраты на текущий день.
-- Суммарный НДС на текущий день.
-- Суммарную валовую прибыль на текущий день.
-- Долю валовой прибыли в выручке за этот день (долю п.4 в п.1).
-- Долю суммарной валовой прибыли в суммарной выручке на текущий день (долю п.8 в п.5).
-- Колонки с показателями назовите соответственно revenue, costs, tax, gross_profit, total_revenue, total_costs, total_tax, total_gross_profit, gross_profit_ratio, total_gross_profit_ratio
-- Колонку с датами назовите date.

-- Долю валовой прибыли в выручке необходимо выразить в процентах, округлив значения до двух знаков после запятой.
-- Результат должен быть отсортирован по возрастанию даты.
-- Поля в результирующей таблице: date, revenue, costs, tax, gross_profit, total_revenue, total_costs, total_tax, total_gross_profit, gross_profit_ratio,total_gross_profit_ratio

-- Чтобы посчитать затраты, в этой задаче введём дополнительные условия.
-- В упрощённом виде затраты нашего сервиса будем считать как сумму постоянных и переменных издержек. К постоянным издержкам отнесём аренду складских помещений, а к переменным — стоимость сборки и доставки заказа. Таким образом, переменные затраты будут напрямую зависеть от числа заказов.
-- Из данных, которые нам предоставил финансовый отдел, известно, что в августе 2022 года постоянные затраты составляли 120 000 рублей в день. Однако уже в сентябре нашему сервису потребовались дополнительные помещения, и поэтому постоянные затраты возросли до 150 000 рублей в день.
-- Также известно, что в августе 2022 года сборка одного заказа обходилась нам в 140 рублей, при этом курьерам мы платили по 150 рублей за один доставленный заказ и ещё 400 рублей ежедневно в качестве бонуса, если курьер доставлял не менее 5 заказов в день. В сентябре продакт-менеджерам удалось снизить затраты на сборку заказа до 115 рублей, но при этом пришлось повысить бонусную выплату за доставку 5 и более заказов до 500 рублей, чтобы обеспечить более конкурентоспособные условия труда. При этом в сентябре выплата курьерам за один доставленный заказ осталась неизменной.

-- Пояснение: 

-- При расчёте переменных затрат учитывайте следующие условия:
-- 1. Затраты на сборку учитываются в том же дне, когда был оформлен заказ. Сборка отменённых заказов не производится.
-- 2. Выплата курьерам за доставленный заказ начисляется сразу же после его доставки, поэтому если курьер доставит заказ на следующий день, то и выплата будет учтена в следующем дне.
-- 3. Для получения бонусной выплаты курьерам необходимо доставить не менее 5 заказов в течение одного дня, поэтому если курьер примет 5 заказов в течение дня, но последний из них доставит после полуночи, бонусную выплату он не получит.

-- При расчёте НДС учитывайте, что для некоторых товаров налог составляет 10%, а не 20%. Список товаров со сниженным НДС:
-- 'сахар', 'сухарики', 'сушки', 'семечки', 'масло льняное', 'виноград', 'масло оливковое', 'арбуз', 'батон', 'йогурт', 'сливки', 'гречка', 'овсянка', 'макароны', 'баранина', 'апельсины', 'бублики', 'хлеб', 'горох', 'сметана', 'рыба копченая', 'мука', 'шпроты', 'сосиски', 'свинина', 'рис', 'масло кунжутное', 'сгущенка', 'ананас', 'говядина', 'соль', 'рыба вяленая', 'масло подсолнечное', 'яблоки', 'груши', 'лепешка', 'молоко', 'курица', 'лаваш', 'вафли', 'мандарины'

-- Также при расчёте величины НДС по каждому товару округляйте значения до двух знаков после запятой.
-- При расчёте выручки по-прежнему будем считать, что оплата за заказ поступает сразу же после его оформления, т.е. случаи, когда заказ был оформлен в один день, а оплата получена на следующий, возникнуть не могут.

with revenue_tab as (
    SELECT date, sum(price) as revenue
    FROM (
        SELECT creation_time::date as date, unnest(product_ids) as product_id
        FROM orders 
        WHERE order_id not in (SELECT order_id FROM user_actions WHERE action = 'cancel_order') ) t1
        JOIN products using (product_id)
    GROUP BY date
    ORDER BY date
),
cost_tab as (
    SELECT date, case 
            when date <'2022-09-01' then cor*(140)+120000+bonus
            else cor*(115)+150000+bonus
        end as costs
    FROM (
        SELECT date, count(DISTINCT order_id) as cor
        FROM (SELECT creation_time::date as date, order_id
                FROM orders
                where order_id not in (SELECT order_id FROM user_actions WHERE action = 'cancel_order') 
             ) t2 
        group by date) t3
    JOIN (SELECT date, sum(bonus1) as bonus 
            from (
                SELECT date, courier_id, corc,
                            case 
                                when date <'2022-09-01' and corc > 4 then corc*150+400
                                when date >='2022-09-01' and corc > 4 then corc*150+500
                                else corc*150
                            end as bonus1
                FROM (
                            SELECT time::date as date, count(DISTINCT order_id) as corc, courier_id
                            FROM courier_actions
                            where action = 'deliver_order' and order_id not in (SELECT order_id FROM user_actions WHERE action = 'cancel_order')
                            group by courier_id, date 
                     ) t4   
                ) t5 
            GROUP BY date
        ) tt1 using (date)
    GROUP BY date, cor, bonus
    ORDER by date
),
tax_tab as (
   SELECT date, sum(round(case
        when name in ('сахар', 'сухарики', 'сушки', 'семечки', 
'масло льняное', 'виноград', 'масло оливковое', 
'арбуз', 'батон', 'йогурт', 'сливки', 'гречка', 
'овсянка', 'макароны', 'баранина', 'апельсины', 
'бублики', 'хлеб', 'горох', 'сметана', 'рыба копченая', 
'мука', 'шпроты', 'сосиски', 'свинина', 'рис', 
'масло кунжутное', 'сгущенка', 'ананас', 'говядина', 
'соль', 'рыба вяленая', 'масло подсолнечное', 'яблоки', 
'груши', 'лепешка', 'молоко', 'курица', 'лаваш', 'вафли', 'мандарины') then price / 1.1 * 0.1::decimal 
        else price / 1.2 * 0.2::decimal end, 2) ) as tax 
    FROM (
        SELECT creation_time::date as date, unnest(product_ids) as product_id
        FROM orders 
        WHERE order_id not in (SELECT order_id FROM user_actions WHERE action = 'cancel_order') 
         ) t6
     JOIN products using (product_id)
    GROUP BY date
    ORDER BY date
), 
fin_tab as (
    SELECT date, revenue, costs, tax,
        revenue-(costs+tax) as gross_profit,
        SUM(revenue) OVER(ORDER BY date) as total_revenue,
        SUM(costs) OVER(ORDER BY date) as total_costs, 
        SUM(tax) OVER(ORDER BY date) as total_tax, 
        SUM(revenue-(costs+tax) ) OVER(ORDER BY date) as total_gross_profit
    FROM revenue_tab 
        JOIN cost_tab using (date)
        JOIN tax_tab using (date)
)
SELECT date, revenue, costs, tax, gross_profit, total_revenue, total_costs, total_tax, total_gross_profit,    
    ROUND(100.0 * gross_profit / revenue, 2) AS gross_profit_ratio,
    ROUND(100.0 * total_gross_profit /total_revenue, 2) AS total_gross_profit_ratio
FROM fin_tab

    
