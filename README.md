# Brazilian-E-Commerce-Performance-Analysis
End-to-End Data Analysis of Olist E-Commerce Data with Excel, Pandas, SQL &amp; Power BI

## Project Overview

This project analyzes the Olist Brazilian E-Commerce dataset — a real-world, multi-table dataset covering ~99,000 orders across customers, products, sellers, payments, and reviews. The goal is to identify revenue drivers, category performance, delivery reliability, and customer satisfaction patterns using a full analytics stack: Excel for exploratory data analysis, Pandas for cleaning and merging relational data, SQL for multi-table querying, and Power BI for interactive dashboard.

**Dataset:** [Brazilian E-Commerce Public Dataset by Olist (Kaggle)](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)


## Business Questions

1. Which product categories generate the highest revenue, and which sell in high volume but underperform in revenue?
2. Does delivery time (purchase → delivered) impact customer review scores?
3. Which states/cities have the highest customer concentration, and what is the average order value there?
4. How does payment type (credit card, boleto, voucher, etc.) relate to average order value and installment behavior?
5. Which sellers generate the most revenue, and how does their delivery performance compare?
6. What percentage of orders are delivered late versus on-time or early, and does this vary by region?
7. Which product categories receive the most negative (1–2 star) reviews, and is this linked to delivery delays?
8. How does freight (shipping) cost compare to product price across categories?


## Excel Analysis

Before any merging or cleaning, each raw table was explored independently in Excel using PivotTables to understand structure, distributions, and data quality issues.

1. Order Status Breakdown: Of 99,441 total orders, 96,478 (97%) are marked delivered. The remainder are split across shipped (1,107), canceled (625), unavailable (609), invoiced (314), processing (301), created (5), and approved (2). Canceled/ unavailable orders will be excluded from revenue calculations in later stages to avoid inflating sales figures.
2. Order Volume Trend: Grouping orders by year-month revealed steady month-over-month growth from early 2017 through mid-2018. Two data coverage boundaries were identified: negligible order volume in late 2016 (dataset ramp-up) and a sharp drop after September 2018 (dataset cutoff, not a real business decline). Both periods will be handled carefully in trend analysis to avoid misleading conclusions.
3. Payment Method Analysis: Across $16.0M in total transacted value, credit_card dominates with $12.5M (78%), followed by boleto (a Brazilian bank-slip payment method) at $2.87M, voucher at $379K, and debit_card at $218K. Notably, voucher transactions have the lowest average value ($65.70) compared to credit card ($163.32), suggesting vouchers are typically used for smaller or discounted purchases. A minor data quality issue was found: 3 records are tagged not_defined with $0 value.
4. Review Score Distribution: Of 99,224 reviews, 57.78% are 5-star and 19.29% are 4-star, meaning over 77% of reviews are positive. However, 11.51% are 1-star — a meaningful share worth cross-referencing against delivery performance in later stages.
5. Delivery Performance: A delivery_delay_days metric was calculated (actual delivery date minus estimated delivery date). 88,649 orders (89.15%) were delivered on-time or early, 7,827 orders (7.87%) were delivered late, and 2,965 orders (2.98%) have no delivery date recorded (order lost, canceled, or in transit).
6. Order Items (Price & Freight): Across 112,650 individual line items, total product price sold is $13.59M (average item price: $120.65), with total freight (shipping) cost of $2.25M.
7. Geographic Concentration: Customers are heavily concentrated in São Paulo state (SP: 41,746 customers, ~42% of all customers), followed by Rio de Janeiro (RJ: 12,852) and Minas Gerais (MG: 11,635). Seller concentration is even more skewed toward SP: 1,849 of 3,095 sellers (~60%) are based there — indicating SP functions as the dataset's primary commercial hub for both supply and demand.

📊 [View Excel Analysis Files](https://github.com/nazmossakib89-maker/Brazilian-E-Commerce-Performance-Analysis/tree/main/Excel%20Analysis)


## Pandas: Data Cleaning & Merging

With the raw tables individually understood from the Excel stage, Python (Pandas) was used to correct data types, engineer new fields, and merge five relational tables into a single analytical dataset, using merge() for key-based joins and groupby() to pre-aggregate one-to-many tables before joining.

1. Data Type Correction & Delivery Delay: All date/timestamp columns were converted from text to proper datetime64 objects, cutting the table's memory usage nearly in half and enabling direct date arithmetic. A delivery_delay_days column was then engineered as the gap between estimated and actual delivery dates — Pandas correctly propagates NaN for undelivered orders instead of producing corrupted values, unlike the equivalent Excel formula.
2. Pre-Aggregating One-to-Many Tables: Since order_payments and order_reviews can contain multiple records per order, both were first collapsed to one row per order_id via groupby("order_id").agg() — summing installment payments and averaging review scores — before being merged, to prevent row-multiplication errors.
3. Building the Master Dataset: orders was left-joined sequentially to order_items, the pre-aggregated payments and reviews tables, products (with English category names merged in), and finally customers/sellers for geographic attributes. Left joins were used throughout to preserve every order, including 775 orders with no item records — traced back to unavailable and canceled statuses, consistent with the Excel-stage findings.
4. Data Quality Fix: Missing Product: Categories 623 unique products were found missing an English category name. Root-cause analysis showed 610 had a blank category in the source data, while 13 belonged to two valid categories simply absent from the translation file. The two known categories were manually mapped; the rest were labeled "unknown" rather than dropped, preserving their revenue data.
5. Final Dataset: The cleaned dataset contains 113,425 rows and 24 columns, combining order, item, payment, review, product, customer, and seller data. All remaining missing values are logically explained rather than errors, and the result was exported to olist_full_data_cleaned.csv for the SQL and Power BI stages.

📊 [View Full Pandas Analysis Notebook](https://github.com/nazmossakib89-maker/Brazilian-E-Commerce-Performance-Analysis/blob/main/Pandas%20Analysis/pandas_analysis.ipynb)


## SQL Analysis

The eight raw tables were loaded into a MySQL database (rather than the pre-merged Pandas dataset) specifically to demonstrate multi-table JOINs, subqueries, and aggregate SQL — building a normalized schema from scratch and answering each business question directly against it.

Data Import All eight CSVs were loaded via LOAD DATA INFILE rather than the GUI import wizard, using NULLIF() on staged variables to convert blank strings to proper NULL values for numeric and date columns. The reviews file required additional preprocessing in Python: MySQL's parser does not reliably handle CSV fields with inconsistent quoting, so the source file was regenerated with every field fully quoted before import. Row counts for all eight tables were verified against the Excel and Pandas stages before any analysis began.

**Q1 — Category Revenue** health_beauty is the top revenue-generating category ($1.26M from 9,670 items), narrowly ahead of watches_gifts ($1.2M from just 5,991 items) — the latter's higher average item price ($201 vs. $130) makes it a high-value, lower-volume driver, distinct from high-volume categories like bed_bath_table that generate revenue through scale rather than price.

**Q2 — Delivery Delay vs. Review Score** This is the project's strongest finding: average review score drops from 4.29 for on-time/early deliveries to 2.57 for late ones — a nearly 40% decline — confirming delivery reliability as a primary driver of customer satisfaction.

**Q3 — Geographic Distribution** São Paulo (SP) dominates in order volume (41,745 orders) but has the lowest average order value ($137.50) of the top 10 states, while smaller states like Bahia (BA) and Santa Catarina (SC) show notably higher average order values (up to $170.82) despite far lower volume.

**Q4 — Payment Behavior** credit_card payments average 3.5 installments, versus exactly 1.0 for boleto, voucher, and debit card — indicating installment flexibility is likely a key reason credit card transactions carry a higher average value ($163) than other payment types.

**Q5 — Seller Performance** Among the top 10 sellers by revenue, 9 are based in SP, consistent with the platform's supply concentration. Late-delivery rates among top sellers range from 4.19% to 14.32%, showing that high revenue does not always correlate with strong delivery reliability.

**Q6 — Delivery Timeliness** 89.15% of orders are delivered on-time or early, 7.87% are late, and 2.98% have no recorded delivery date — consistent with the Excel-stage findings, confirmed independently via SQL.

**Q7 — Negative Reviews by Category** fashion_male_clothing (28.24%) and office_furniture (26.08%) have the highest shares of 1–2 star reviews among categories with at least 30 reviews. Furniture-related categories appear repeatedly in this list, suggesting a possible link to shipping damage or delivery issues for bulky items.

**Q8 — Freight-to-Price Ratio** home_comfort_2 and flowers have the most disproportionate shipping costs, with average freight equal to 54% and 44% of the product price respectively — a ratio likely to discourage purchases and worth flagging for pricing or logistics review.




