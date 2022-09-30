/*

Cleaning Data in SQL Queries

*/

Select*
FROM Nashville_Housing.dbo.nashville
--------------------------------------------------

---Change Date type
--The time serves no function in the data so wanted to make the date column more usable for data presentation. 

--Attempted this method to convert, however it would not run properly.
SELECT SaleDate, CONVERT(Date,saledate)
FROM Nashville_Housing.dbo.nashville

UPDATE Nashville
SET SaleDate = Convert(Date,SaleDate)

SELECT saledate
FROM Nashville_Housing.dbo.nashville

--So in order to work around that issue, I created a new column which I then poplated with the new date format.

ALTER TABLE nashville
ADD SaleDateConverted Date;

UPDATE nashville
SET SaleDateConverted = CONVERT(Date,SaleDate)

SELECT Saledateconverted
FROM Nashville_Housing.dbo.nashville

---------------------------------------------------

---Populate Porperty Address Data 

select *
FROM Nashville_Housing.dbo.nashville
WHERE PropertyAddress IS NULL

--We could populate the Porperty Address if we had a refrence point.

select *
FROM Nashville_Housing.dbo.nashville
ORDER BY ParcelID

--One thing we see is that Property Address is the same with ParcelID.
--So we can then say that if a ParcelId has an address and then for another record with the same ParcelID does not have an address, let's populate it with same address.

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.propertyaddress, b.PropertyAddress)
FROM Nashville_Housing.dbo.nashville a
JOIN Nashville_Housing.dbo.nashville b
	ON a.ParcelID = b.ParcelID
	AND A.[UniqueID ] <> B.[UniqueID ]
WHERE a.PropertyAddress is null


UPDATE a
SET PropertyAddress = ISNULL(a.propertyaddress, b.PropertyAddress)
FROM Nashville_Housing.dbo.nashville a
JOIN Nashville_Housing.dbo.nashville b
	ON a.ParcelID = b.ParcelID
	AND A.[UniqueID ] <> B.[UniqueID ]
WHERE a.PropertyAddress is NULL


------------------------------------------------

---Bring out Address into Individual Columns (Address, City, State)
--We would do this in order to make the data more usable for presentation.

SELECT PropertyAddress
FROM Nashville_Housing.dbo.nashville

--The following substring allows us to pull apart the Address and City which we will then make into their own columns. 
SELECT 
SUBSTRING(PROPERTYADDRESS, 1, CHARINDEX(',',PropertyAddress) -1 ) as Address,
SUBSTRING(PROPERTYADDRESS, CHARINDEX(',',PropertyAddress) +1, LEN(PropertyAddress)) as City
FROM Nashville_Housing.dbo.nashville

ALTER TABLE nashville
Add PropertySplitAddress nvarchar(255);

UPDATE nashville
SET PropertySplitAddress = SUBSTRING(PROPERTYADDRESS, 1, CHARINDEX(',',PropertyAddress) -1 )

ALTER TABLE nashville
ADD PropertySplitCity nvarchar(255);

UPDATE nashville
SET PropertySplitCity = SUBSTRING(PROPERTYADDRESS, CHARINDEX(',',PropertyAddress) +1, LEN(PropertyAddress))

UPDATE nashville 
SET PropertySplitCity = UPPER(PropertySplitCity)

SELECT*
FROM Nashville_Housing.dbo.nashville

--Owners Address has many NULL values that can be filled in with the information from Property Address. 

SELECT OwnerAddress
FROM Nashville_Housing.dbo.nashville

SELECT a.ParcelID, a.OwnerAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.OwnerAddress, b.PropertyAddress)
FROM Nashville_Housing.dbo.nashville a
JOIN Nashville_Housing.dbo.nashville b
	ON a.ParcelID = b.ParcelID
	AND A.[UniqueID ] <> B.[UniqueID ]
WHERE a.OwnerAddress is null


UPDATE a
SET OwnerAddress = ISNULL(a.OwnerAddress, b.PropertyAddress)
FROM Nashville_Housing.dbo.nashville a
JOIN Nashville_Housing.dbo.nashville b
	ON a.ParcelID = b.ParcelID
	AND A.[UniqueID ] <> B.[UniqueID ]
WHERE a.OwnerAddress is NULL

--To make the data in Owners Address more usable we will also split it up my Address and City and State when applicable.

SELECT PARSENAME(REPLACE(OwnerAddress,',','.'),3),
PARSENAME(REPLACE(OwnerAddress,',','.'),2),
PARSENAME(REPLACE(OwnerAddress,',','.'),1)
FROM Nashville_Housing.dbo.nashville


ALTER TABLE nashville
Add OwnerSplitAddress nvarchar(255);

UPDATE nashville
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3);

ALTER TABLE nashville
ADD OwnerSplitCity nvarchar(255);

UPDATE nashville
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2)

ALTER TABLE nashville
ADD OwnerSplitState nvarchar(255);

UPDATE nashville
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)

---------------------------------------------------

---Change Y and N to Yes and No in "Sold as Vacant" Field

SELECT DISTINCT(SOLDASVACANT), COUNT(soldasvacant) as Amount
FROM nashville
GROUP BY SoldAsVacant
ORDER BY Amount

SELECT SoldasVacant,
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
		 END
FROM nashville

UPDATE nashville
SET SoldasVacant = 
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
		 END
FROM nashville

SELECT *
FROM Nashville_Housing.DBO.nashville

--Remove Duplicates (Since there are UniqueIDs in this data set it is easy to find that there are no duplicates. However I wanted to present a method of looking for them if there was no UniqueID.)
--Created a temp table to present this from which I will delete the duplicates to not affect the main data.

Create Table #DeleteDuplicatesNashville 
(ParcelID nvarchar(255), PropertyAddress nvarchar(255), SalePrice float, SaleDateConverted date, LegalReference nvarchar(255))

Insert into #DeleteDuplicatesNashville
SELECT ParcelID, PropertyAddress, SalePrice, SaleDateConverted,LegalReference
FROM Nashville_Housing.dbo.nashville

--Verify everything was populated correctly
Select *
From #DeleteDuplicatesNashville

--Check for duplicates in the Temp Table. Found 104 duplicate records.
SELECT ParcelID, PropertyAddress, SalePrice, SaleDateConverted,LegalReference
FROM #DeleteDuplicatesNashville
GROUP BY ParcelID, PropertyAddress, SalePrice, SaleDateConverted,LegalReference
HAVING COUNT(*) > 1

--Another method to find the duplicates to delete is a CTE function
WITH DeleteDuplicatesNashvilleCTE AS (
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDateConverted,
				 LegalReference
				ORDER BY ParcelID) as RowNumber
FROM #DeleteDuplicatesNashville)

--SELECT* (To see the amount of duplicate records)
DELETE
FROM DeleteDuplicatesNashvilleCTE
WHERE RowNumber > 1

--This would be used to delete the records from the main data instead of just a TempTable. 
WITH RowNumCTE AS (
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY UniqueID) row_num
FROM Nashville_Housing.dbo.nashville
)

SELECT * 
FROM RowNumCTE
WHERE row_num > 1



--Delete Unused Columns (Not usually done in real company data but presenting the query on how to.)

SELECT *
FROM nashville

ALTER TABLE nashville
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

ALTER TABLE nashville
DROP COLUMN SaleDate

