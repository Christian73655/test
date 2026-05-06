WITH deduped_aum AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY AS_OF_DATE, ACCOUNT_NUMBER, SERIES_NUMBER
               ORDER BY GROSS_AUM DESC
           ) AS rn
    FROM MARKET_HUB.REPORTING.AUM_NET
),

deduped_static AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY ticker_or_fundserv
               ORDER BY to_date DESC
           ) AS rn
    FROM MARKET_HUB.REPORTING.CIBC_STATIC_FUND_DATA
    WHERE to_date >= '2999-01-01'
)

SELECT
    a.AS_OF_DATE,
    a.ACCOUNT_NUMBER,
    a.SERIES_NUMBER,
    a.GROSS_AUM,
    a.MATCHED_SECURITY_NUMBER,
    a.MATCH_TYPE,
    a.FUND_OF_FUND_AUM,
    a.units,
    a.fund_of_fund_units,
    a.FUND_CLASSIFICATION,
    a.FINANCE_CATEGORY,
    a.MGMT_FEE_RATE,
    a.ADMIN_FEE_RATE,
    a.FX_RATE,
    d.Category AS strategy,
    d.focus,
    d.type,
    CASE 
        WHEN a.fund IN ('CASHACCT4', 'CASHACCT9') THEN 'PSIF' 
        ELSE a.fund 
    END AS fund
FROM deduped_aum AS a
LEFT JOIN deduped_static d 
    ON a.TICKER_OR_FUND_SERV = d.ticker_or_fundserv
    AND d.rn = 1
WHERE a.rn = 1
  AND a.AS_OF_DATE NOT IN (
      SELECT DATE FROM MARKET_HUB_DEV.UTILS.HOLIDAYS
  );
