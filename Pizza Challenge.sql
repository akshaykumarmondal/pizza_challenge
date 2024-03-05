create database dannys_dinner;
use dannys_dinner;

create table sales(
    customer_id varchar(1),
	order_date datetime,
    product_id integer
);

create table menu(
	product_id integer,
    product_name varchar(5),
    price integer
);

create table members(
	customer_id varchar(1),
    join_date date
);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
  
  INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  
  INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
  # Answer 1> What is the total amount each customer spent at the restaurant?
  select s.customer_id, sum(m.price) as total_amount from 
  sales s inner join menu m  
  on m.product_id = s.product_id
  group by s.customer_id;
  
  # Answer 2> How many days has each customer visited the restaurant?
  select customer_id, count(distinct order_date) as number_of_visits
  from sales
  group by customer_id;
  
  # Answer 3> What was the first item from the menu purchased by each customer?
  with first_product as (select customer_id, order_date, product_name, price,
  row_number() over(partition by customer_id order by order_date) first_food
  from sales s inner join menu m
  on s.product_id = m.product_id)
  select customer_id,product_name
  from first_product
  where first_food = 1;
  
  # Answer 4> What is the most purchased item on the menu and how many times was it purchased by all customers?
  select m.product_name, count(m.product_id) as most_sales
  from 
  sales s inner join menu m
  on s.product_id = m.product_id
  group by m.product_name
  order by most_sales desc
  limit 1;
  
  # Answer 5> Which item was the most popular for each customer?
  with most_popular_item as (select m.product_name, s.customer_id, count(s.order_date) as number_of_orders, 
  row_number() over(partition by s.customer_id order by count(s.order_date) desc) as rn
  from
  menu m inner join sales s 
  on m.product_id = s.product_id
  group by m.product_name,s.customer_id )
  select product_name, customer_id, number_of_orders from 
  most_popular_item
  where rn = 1;
  
  # Answer 6> Which item they purchased first after they become a member>
  with first_order as( select mm.customer_id, mm.join_date ,s.order_date,s.product_id,
  row_number() over(partition by mm.customer_id order by s.order_date) as rn
  from members mm left join sales s 
  on mm.join_date <= s.order_date and mm.customer_id = s.customer_id
  order by mm.customer_id,s.order_date)
  select customer_id,join_date,order_date,product_name
  from first_order fo 
  inner join menu m
  on fo.product_id = m.product_id
  where rn = 1
  order by customer_id;
  
  # Answer 7> Which item was purchased just before the customer became a member?
  with order_before_member as (select mm.customer_id, mm.join_date ,s.order_date,s.product_id,
  row_number() over(partition by mm.customer_id order by s.order_date desc) as rn
  from members mm left join sales s
  on mm.customer_id = s.customer_id and mm.join_date > s.order_date)
  select customer_id, order_date, product_name
  from order_before_member obm inner join menu m
  on obm.product_id = m.product_id
  where rn = 1
  order by customer_id;
  
  # Answer 8> What is the total items and amount spent for each member before they became a member?
  with before_memberships as(select m.customer_id,m.join_date,s.order_date,s.product_id
  from members m join sales s
  on m.customer_id = s.customer_id and m.join_date > s.order_date)
  select bm.customer_id,count(bm.order_date) as number_of_items,sum(me.price) as total_price
  from
  before_memberships bm join menu me
  on bm.product_id = me.product_id
  group by bm.customer_id
  order by bm.customer_id;
  
  # Answer 9> If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
  with points_table as (select s.customer_id, s.order_date, s.product_id, m.product_name, m.price,
  case 
	when m.product_name = 'sushi' then m.price*20 
    else m.price*10
  end as points
  from sales s join menu m 
  on s.product_id = m.product_id)
  select customer_id,sum(points) as total_points
  from points_table
  group by customer_id;
  
  # Answer 10>In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
  # not just sushi - how many points do customer A and B have at the end of January?
  select mm.customer_id,
  sum(case 
	when s.order_date between mm.join_date and DATE_ADD(mm.join_date, INTERVAL 6 DAY) then m.price * 10 * 2
    when m.product_name = 'sushi' then m.price * 10 * 2
    else m.price * 10
  end) as points
  from menu as m 
  inner join sales s on s.product_id = m.product_id
  inner join members as mm on mm.customer_id = s.customer_id
  group by s.customer_id;
  
  # Answer Bonus Question 1> Join all the things and represent the data in such a way that
  #					shows which customers are members 
 select s.customer_id,s.order_date,m.product_name,m.price,
 case 
	when mm.join_date < s.order_date then 'Y'
    else 'N'
 end as members
 from sales s inner join menu m 
 on s.product_id = m.product_id
 inner join members mm on  s.customer_id = mm.customer_id
 order by s.customer_id,s.order_date;
 
 # Answer Bonus Question 2> Rank all the things keeping the customers who are not members as null
 with mem_proofs as (select s.customer_id,s.order_date,m.product_name,m.price,
 case 
	when mm.join_date < s.order_date then 'Y'
    else 'N'
 end as members
 from sales s inner join menu m 
 on s.product_id = m.product_id
 inner join members mm on  s.customer_id = mm.customer_id)
select customer_id,order_date,product_name,price,members,
 case 
	when members = 'N' then null
 else row_number() over(partition by s.customer_id order by s.order_date)
end as ranking
from mem_proofs
  
  
  
  
  
  
  
  
  

