/* Cleaning Nashville Housing Data in SQL. 
Skills Used: data type conversion, text functions, JOIN, common table expression, window functions, CASE statement,
updating table, altering table, deleting rows, droping columns */

SELECT *
FROM [PortfolioProjects].[dbo].[housing]
ORDER BY ParcelID

--Change SaleDate to date type
ALTER TABLE [PortfolioProjects].[dbo].[housing]
ADD NewSaleDate DATE;

UPDATE [PortfolioProjects].[dbo].[housing]
SET NewSaleDate = CAST(SaleDate AS date);

-- Some properties are duplicated with duplicate not having the address
SELECT *
FROM [PortfolioProjects].[dbo].[housing]
WHERE PropertyAddress IS NULL
ORDER BY ParcelID

-- make properties with null addresses have the same address as their duplicate
SELECT 
	t1.ParcelID, 
	t1.PropertyAddress, 
	t2.ParcelID, 
	t2.PropertyAddress, 
	COALESCE(t1.PropertyAddress,t2.PropertyAddress) as PropertyAddress
FROM [PortfolioProjects].[dbo].[housing] AS t1
JOIN [PortfolioProjects].[dbo].[housing] AS t2
	ON t1.ParcelID = t2.ParcelID
	AND t1.[UniqueID ] <> t2.[UniqueID ]
WHERE t1.PropertyAddress IS NULL
ORDER BY t1.ParcelID

UPDATE t1
SET PropertyAddress = COALESCE(t1.PropertyAddress,t2.PropertyAddress)
	FROM [PortfolioProjects].[dbo].[housing] AS t1
	JOIN [PortfolioProjects].[dbo].[housing] AS t2
		ON t1.ParcelID = t2.ParcelID
		AND t1.[UniqueID ] <> t2.[UniqueID ]
	WHERE t1.PropertyAddress IS NULL

SELECT *
FROM [PortfolioProjects].[dbo].[housing] 
WHERE PropertyAddress IS NULL -- no returns: suceessful

--Create property street name and city name columns from PropertyAddress
SELECT 
	PropertyAddress,
	TRIM(LEFT(PropertyAddress,CHARINDEX(',',PropertyAddress)-1)) AS PropertyStreet,
	TRIM(SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress))) AS PropertyCity
FROM [PortfolioProjects].[dbo].[housing]

ALTER TABLE [PortfolioProjects].[dbo].[housing]
ADD PropertyStreet NVARCHAR(255), PropertyCity NVARCHAR(255);

UPDATE [PortfolioProjects].[dbo].[housing]
SET PropertyStreet = TRIM(LEFT(PropertyAddress,CHARINDEX(',',PropertyAddress)-1)),
	PropertyCity = TRIM(SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress)));

--Create owner street name and city name columns from OwnerAddress
SELECT 
	OwnerAddress,
	TRIM(PARSENAME(REPLACE(OwnerAddress,',','.'),1)) AS OwnerState,
	TRIM(PARSENAME(REPLACE(OwnerAddress,',','.'),2)) AS OwnerCity,
	TRIM(PARSENAME(REPLACE(OwnerAddress,',','.'),3)) AS OwnerStreet
FROM [PortfolioProjects].[dbo].[housing]

ALTER TABLE [PortfolioProjects].[dbo].[housing]
ADD OwnerState NVARCHAR(255), OwnerCity NVARCHAR(255), OwnerStreet NVARCHAR(255);

UPDATE [PortfolioProjects].[dbo].[housing]
SET OwnerState = TRIM(PARSENAME(REPLACE(OwnerAddress,',','.'),1)),
	OwnerCity = TRIM(PARSENAME(REPLACE(OwnerAddress,',','.'),2)),
	OwnerStreet = TRIM(PARSENAME(REPLACE(OwnerAddress,',','.'),3));

--Standardize sold as vacant to Yes and NO
SELECT DISTINCT SoldASVacant 
FROM [PortfolioProjects].[dbo].[housing]

SELECT DISTINCT
	CASE 
		WHEN SoldASVacant ='N' THEN 'No'
		WHEN SoldASVacant ='Y' THEN 'Yes'
	ELSE SoldAsVacant END
FROM [PortfolioProjects].[dbo].[housing]

UPDATE [PortfolioProjects].[dbo].[housing]
SET SoldAsVacant = CASE 
	WHEN SoldASVacant ='N' THEN 'No'
	WHEN SoldASVacant ='Y' THEN 'Yes'
	ELSE SoldAsVacant END

--Find and delete duplicates - appopriate for properties with the same  parcel ID, address and sales information.
WITH NumEntriesCTE AS
	(SELECT 
		*, 
		ROW_NUMBER() OVER(
			PARTITION BY 
				ParcelID, 
				PropertyAddress, 
				SalePrice, 
				SaleDate,
				LegalReference
			ORDER BY ParcelID)AS NumEntries
	FROM [PortfolioProjects].[dbo].[housing])

DELETE
FROM NumEntriesCTE
WHERE NumEntries > 1

--Delete unnecessary columns as per instructions and make NewSaleDate SaleDate
ALTER TABLE [PortfolioProjects].[dbo].[housing]
DROP COLUMN OwnerAddress, PropertyAddress, SaleDate;

ALTER TABLE [PortfolioProjects].[dbo].[housing]
ADD SaleDate DATE;

UPDATE [PortfolioProjects].[dbo].[housing]
SET SaleDate = NewSaleDate;

ALTER TABLE [PortfolioProjects].[dbo].[housing]
DROP COLUMN NewSaleDate;