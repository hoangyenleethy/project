USE Project;

-- Calculate Recency, Frequency, and Monetary
WITH RFM AS (
    SELECT
        ID,
        DATEDIFF(DAY, MAX(Dt_Customer), '2014-12-31') AS Recency,
        SUM(NumCatalogPurchases + NumWebPurchases + NumStorePurchases) AS Frequency,
        SUM(MntFishProducts + MntFruits + MntGoldProds + MntMeatProducts + MntSweetProducts + MntWines) AS Monetary
    FROM
        dbo.mktdata
    GROUP BY
        ID
),

-- Calculate ranks
Rank_table AS (
    SELECT
        *,
        PERCENT_RANK() OVER (ORDER BY Frequency) AS F_Rank,
        PERCENT_RANK() OVER (ORDER BY Monetary) AS M_Rank
    FROM
        RFM
),

-- Scoring (over 2 years are omitted)
Scoring AS (
    SELECT
        ID,
        CASE
            WHEN Recency BETWEEN 0 AND 120 THEN 3
            WHEN Recency BETWEEN 121 AND 370 THEN 2
            WHEN Recency BETWEEN 371 AND 730 THEN 1
            ELSE 0
        END AS Recency_rank,
        CASE
            WHEN F_Rank BETWEEN 0.8 AND 1 THEN 3
            WHEN F_Rank BETWEEN 0.5 AND 0.8 THEN 2
            WHEN F_Rank BETWEEN 0 AND 0.5 THEN 1
            ELSE 0
        END AS Frequency_Rank,
        CASE
            WHEN M_Rank BETWEEN 0.8 AND 1 THEN 3
            WHEN M_Rank BETWEEN 0.5 AND 0.8 THEN 2
            WHEN M_Rank BETWEEN 0 AND 0.5 THEN 1
            ELSE 0
        END AS Monetary_Rank
    FROM
        Rank_table
)

-- Create the Scoring table
SELECT *
INTO Scoring
FROM Scoring;

select * from Scoring

ALTER TABLE Scoring
ADD CustomerType NVARCHAR(50);

UPDATE Scoring
SET CustomerType = 
    CASE
        WHEN Recency_rank in (2, 3) AND Frequency_Rank IN (2, 3) AND Monetary_Rank in (3)THEN 'VIP'
        WHEN Recency_rank IN (2, 3) AND Frequency_Rank IN (2, 3) AND Monetary_Rank IN (1, 2, 3) THEN 'Frequent Customers'
        WHEN Recency_rank IN (2, 3) AND Frequency_Rank IN (1, 2, 3) AND Monetary_Rank IN (1, 2, 3) THEN 'Recent Customers'
        WHEN Recency_rank = 1 AND Frequency_Rank IN (1, 2, 3) AND Monetary_Rank IN (1, 2, 3) THEN 'At risk'
		Else 'Leaving Customer'
    END;
SELECT * FROM Scoring;

USE Project;

-- Extract demographic information and customer type

    SELECT
        m.ID,
        m.Dt_Customer,
        m.Education,
        m.Marital_Status,
        m.Kidhome,
        m.Teenhome,
        m.Income,
        s.CustomerType
    FROM
        dbo.mktdata m
    JOIN
        Scoring s ON m.ID = s.ID

-- Extract campaign reaction and customer type
    SELECT
        m.ID,
        m.AcceptedCmp1,
        m.AcceptedCmp2,
        m.AcceptedCmp3,
        m.AcceptedCmp4,
        m.AcceptedCmp5,
        s.CustomerType
    FROM
        dbo.mktdata m
    JOIN
        Scoring s ON m.ID = s.ID
