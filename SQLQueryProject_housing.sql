/*

Cleaning Data in SQL Queries

*/

SELECT *
FROM porfolio_project.dbo.nashhouse

-- Standardize Date Format

SELECT SaleDatetime, CONVERT(Date, SaleDatetime) -- saledatetime column and just the saledate column
FROM porfolio_project.dbo.nashhouse

ALTER TABLE porfolio_project.dbo.nashhouse
ADD SaleDate date; --add a column called 'SaleDate'

UPDATE nashhouse
SET SaleDate = CONVERT(Date, SaleDatetime) -- convert SaleDatetime column to date datatype and add to SaleDate column

-------------------------------------------
-- Populate Property Address data

SELECT *
FROM porfolio_project.dbo.nashhouse
WHERE PropertyAddress IS NULL -- missing values on property address

SELECT *
FROM porfolio_project.dbo.nashhouse
WHERE ParcelID IS NULL -- the parcel ID column is complete

/*
- there are missing cells for property address which needs to be filled in
- luckily for me, the table contain parcel numbers with associated addresses that can be used to identify the property and complete the missing information
- this can be done, because there are multiple listings of the same property
*/

SELECT nash1.ParcelID, nash1.PropertyAddress, nash2.ParcelID, nash2.PropertyAddress, ISNULL(nash1.PropertyAddress, nash2.PropertyAddress) --returns a specified value if the experession is NULL 
FROM porfolio_project.dbo.nashhouse AS nash1
JOIN porfolio_project.dbo.nashhouse AS nash2 --create two duplicate tables
	ON nash1.ParcelID = nash2.ParcelID -- select only ones where ID is the same
	AND nash1.UniqueID <> nash2.UniqueID -- where the unique ids are different; this makes it so that you can fill in NULL values
	-- using other listings with the same ParcelID
WHERE nash1.PropertyAddress IS NULL -- select where property address is null for table 1 


UPDATE nash1 --update table one
SET PropertyAddress = ISNULL(nash1.PropertyAddress, nash2.PropertyAddress) -- change to correct address where propertyaddress is NULL
FROM porfolio_project.dbo.nashhouse AS nash1
JOIN porfolio_project.dbo.nashhouse AS nash2
	ON nash1.ParcelID = nash2.ParcelID -- select only ones where ID is the same
	AND nash1.UniqueID <> nash2.UniqueID 
WHERE nash1.PropertyAddress IS NULL
-- All null values in property address should then be filled in with the correct address

------------------------------------
-- Breaking address into multiple individual columns (Address, City, State)

SELECT PropertyAddress
FROM porfolio_project.dbo.nashhouse
-- property address contains both address and state or city, which needs to be seperated

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS address 
--search for the delimiter break and cut off the
-- strings after the delimiter; however since we do not want the delimiter showing up we add -1 to cut it out 
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS address 
-- select string after the delimiter
FROM porfolio_project.dbo.nashhouse


ALTER TABLE nashhouse
ADD PropertySplitAddress Nvarchar(255); -- add new column 

UPDATE nashhouse
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) --update the new column


ALTER TABLE nashhouse
ADD PropertySplitCity Nvarchar(255); -- add new column 

UPDATE nashhouse
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) --update the new column

SELECT *
FROM porfolio_project.dbo.nashhouse -- checking our table again should reveal that the address has been split up

-- Performing the same process but with OwnerAddress this time

SELECT OwnerAddress
FROM porfolio_project.dbo.nashhouse

SELECT
PARSENAME(REPLACE(OwnerAddress ,',','.'), 3) 
-- PARSENAME automatically defaults to returning objects between the period delimiter; REPLACE is meant to change that to
-- a comma delimiter
,PARSENAME(REPLACE(OwnerAddress ,',','.'), 2) 
,PARSENAME(REPLACE(OwnerAddress ,',','.'), 1) 
FROM porfolio_project.dbo.nashhouse

-- Now to update the table by creating 3 columns from one of the columns
ALTER TABLE nashhouse
ADD OwnerSplitAddress Nvarchar(255);

UPDATE nashhouse
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress ,',','.'), 3) 

ALTER TABLE nashhouse
ADD OwnerSplitCity Nvarchar(255);

UPDATE nashhouse
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress ,',','.'), 2) 

ALTER TABLE nashhouse
ADD OwnerSplitState Nvarchar(255);

UPDATE nashhouse
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress ,',','.'), 1) 


SELECT OwnerSplitAddress, OwnerSplitCity, OwnerSplitState
FROM porfolio_project.dbo.nashhouse
--------------------------------------
-- SoldAsVacant column contain four values Y, N, Yes, No
-- Change Y and N to YES and NO in "Sold as Vacant" field

SELECT DISTINCT(SoldAsVacant), COUNT(SoldASVACANT) --initially there are 4 values; there needs to be only 2
FROM porfolio_project.dbo.nashhouse
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant, 
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END --confirm that this query works
FROM porfolio_project.dbo.nashhouse

UPDATE nashhouse --Update columns where string is Y and N to Yes and No 
SET SoldAsVacant = 
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END

-------------------------
-- Remove Duplicates
-- Create a common table expression;filter out and delete the duplicates 
WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) AS row_num -- rownum represent the row number in each sequential partition
FROM porfolio_project.dbo.nashhouse
)

DELETE 
FROM RowNumCTE
WHERE row_num > 1 
-- rownum represent the row number in each sequential partition; in our case the second row number is the duplicate value
-- since there is one duplicate for each observation based on what we see in the table
-- we want to delete these duplicates 


-----------------
-- Delete unused columns

SELECT *
FROM porfolio_project.dbo.nashhouse

ALTER TABLE porfolio_project.dbo.nashhouse
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate -- list of columns that I want to delete
