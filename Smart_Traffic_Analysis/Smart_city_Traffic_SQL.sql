use smart_traffic;

show tables from smart_traffic;
select * from book1er;
SET SQL_SAFE_UPDATES = 0;
UPDATE book1er
SET Date = DATE_ADD('1899-12-30', INTERVAL Date DAY);
ALTER TABLE book1er
ADD COLUMN New_Date DATE;
UPDATE book1er
SET New_Date = DATE_ADD('1899-12-30', INTERVAL Date DAY);

select New_Date , Date 
from book1er limit 10;
select * from book1er;

ALTER TABLE book1er
CHANGE COLUMN `PM2.5` PM25 DECIMAL(10,2);

UPDATE book1er
SET 
NO2 = ROUND(NO2,2),
AQI = ROUND(AQI,2),
Uptime_Percentage = ROUND(Uptime_Percentage,2),
Severity_Score = ROUND(Severity_Score,2),
Prev_AQI = ROUND(Prev_AQI,2),
AQI_Change = ROUND(AQI_Change,2),
Traffic_MA_3 = ROUND(Traffic_MA_3,2),
`Congestion_%` = ROUND(`Congestion_%`,2),
CO = ROUND(CO,2),
Smart_City_Index = ROUND(Smart_City_Index,2);

UPDATE book1er
SET Traffic_MA_3= ROUND(Traffic_MA_3/ 100, 1);

ALTER TABLE book1er
CHANGE COLUMN `Congestion_%` Congestion_Percentage DECIMAL(10,2);

ALTER TABLE book1er
CHANGE COLUMN DaY_Type Day_Type VARCHAR(20);
CREATE INDEX idx_city ON book1er(City);
ALTER TABLE book1er
MODIFY COLUMN City VARCHAR(100);
ALTER TABLE book1er
MODIFY COLUMN Zone VARCHAR(100),
MODIFY COLUMN Weather_Condition VARCHAR(100),
MODIFY COLUMN Day_Type VARCHAR(50);









select * from book1er;

/* query to aggregate hourly traffic counts from IoT sensors across all junctions. */
SELECT 
Hour, 
SUM(Traffic_volume) AS Total_Traffic
from book1er
GROUP BY Hour
ORDER BY Hour;

/* How would you join traffic and pollution tables to analyze correlation by timestamp? */
SELECT 
New_Date,
Hour,
City,
Traffic_volume,AQI,PM25,NO2,Congestion_Percentage
FROM book1er
order by Hour;

/* Create a query to detect missing sensor readings in traffic data. */
SELECT 
Sensor_ID,
SUM(CASE WHEN Traffic_volume IS NULL THEN 1 ELSE 0 END) AS Missing_Traffic,
SUM(CASE WHEN AQI IS NULL THEN 1 ELSE 0 END) AS Missing_AQI
FROM book1er
GROUP BY Sensor_ID;

/* Write a SQL query to rank top 10 most congested junctions in the city. */
 SELECT  * 
 FROM (
 SELECT Junction_ID , City , 
 AVG(Congestion_Percentage ) AS Avg_Congestion ,
 RANK() OVER (
      ORDER BY AVG(Congestion_Percentage ) DESC 
      ) AS Congestion_Rank 
   FROM book1er
   Group By Junction_ID , City 
   ) ranked_data 
   Where Congestion_Rank <=10;
      
  /*How would you use window functions to calculate moving averages of pollution levels?
    You can use SQL window functions like AVG() OVER()
    to calculate moving averages of pollution metrics such as AQI, PM25, or NO2.
  */
  SELECT New_Date,City,AQI,
  ROUND(
    AVG(AQI) OVER (
        PARTITION BY City
        ORDER BY New_Date
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) , 2
    )AS Moving_Avg_AQI
FROM book1er;

  /* for PM25 */
  SELECT New_Date,City,PM25,
  ROUND(
    AVG(PM25) OVER (
        PARTITION BY City
        ORDER BY New_Date
        ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
        ),2
    ) AS Moving_Avg_PM25
FROM book1er;

/* for NO2  */
SELECT New_Date,City,NO2,
    ROUND(
    AVG(NO2) OVER (
        PARTITION BY City
        ORDER BY New_Date
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),2
    ) AS Moving_Avg_NO2
FROM book1er;

/* Query to compare traffic density between weekdays and weekends. */
SELECT 
    Day_Type,
    COUNT(*) AS Total_Records,
    ROUND(AVG(Traffic_volume), 2) AS Avg_Traffic_Volume,
    ROUND(MAX(Traffic_volume), 2) AS Peak_Traffic,
    ROUND(AVG(Congestion_Percentage), 2) AS Avg_Congestion,
    ROUND(AVG(AQI), 2) AS Avg_AQI,
    ROUND(AVG(PM25), 2) AS Avg_PM25,
	ROUND(AVG(NO2), 2) AS Avg_NO2,
	ROUND(AVG(Smart_City_Index), 2) AS Avg_Smart_City_Index
FROM book1er
GROUP BY Day_Type
ORDER BY Avg_Traffic_Volume DESC;

/* Write a query to detect outliers in pollution readings (e.g., > 500 AQI) */
Select New_Date ,
City,
ROUND(AQI,2) AS AQI ,
ROUND(PM25,2) AS PM25, 
ROUND(NO2, 2)  AS NO2 ,
Traffic_Volume , 
ROUND(Congestion_Percentage, 2) AS Congestion_Percentage , 
   CASE  
       WHEN AQI > 500  THEN 'Hazardous' 
       WHEN AQI >300 THEN 'Very Poor '
       WHEN AQI > 200  THEN 'Poor ' 
       ELSE 'Moderate ' 
   END AS Pollution_Level 
FROM book1er
WHERE AQI >200 
ORDER BY AQI DESC ;
      
/* How can you partition traffic data by zone and calculate congestion ratios? */
 SELECT 
    Zone,
     COUNT(*) AS Total_Records,
     ROUND(AVG(Traffic_volume), 2) AS Avg_Traffic_Volume,
    ROUND(AVG(Congestion_Percentage), 2) AS Avg_Congestion,
	ROUND(SUM(CASE
                WHEN Congestion_Percentage > 70 THEN 1
                ELSE 0
                END
        )* 100.0/ COUNT(*),2) AS Congestion_Ratio
FROM book1er
GROUP BY Zone
ORDER BY Congestion_Ratio DESC;


/* Create a query to validate sensor uptime percentage across all IoT devices */
Select  Sensor_ID,
Count(*) AS Total_Readings,
Round(avg(Uptime_Percentage),2) as AVG_Uptime_Percentage , 
Round(MIN(Uptime_Percentage),2) AS MIN_Uptime,
Round(MAX(Uptime_Percentage),2) AS Max_Uptime,
Case 
   When AVG(Uptime_Percentage) >= 95 THEN 'Excellent'
   When AVG(Uptime_Percentage) >= 85 THEN 'Good'
   When AVG(Uptime_Percentage) >= 70 THEN 'Moderate'
   ELSE 'Poor'
End As Sensor_Status
from book1er
group by Sensor_ID;


/* Write a query to generate a combined dataset for Power BI ingestion (traffic + pollution) */

CREATE VIEW powerbi_Dataset AS 
Select 
     New_Date, Hour , City , Zone , Junction_ID , Sensor_ID , Traffic_volume, 
     Round(Congestion_Percentage, 2) As Congestion_Percentage , 
     Round(AQI, 2) AS AQI , 
     Round(PM25, 2) AS PM25 ,
     Round(NO2, 2) AS NO2 , 
     Round(CO , 2 ) AS CO , 
     Weather_Condition , 
     Is_Peak_Hour , 
     Day_Type, 
     Is_Weekend , 
     Round(Uptime_Percentage,2)  AS Uptime_Percentage, 
     Round(Smart_City_Index ,2) AS Smart_City_Index
     from book1er;
DESCRIBE book1er;
