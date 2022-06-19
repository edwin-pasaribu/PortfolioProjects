-- This script is for data cleaning method purposes

-- check the data
SELECT
*
FROM nashvillehousing;

-- ----------------------------------------------------------------------------------------------

-- populate blank PropertyAddress
select *
from nashvillehousing
-- where nashvillehousing.PropertyAddress is null;
order by ParcelID;

-- get the null PropertyAddress from ParcelID
select * 
from nashvillehousing a
where a.PropertyAddress is null;

-- check using join for null property, using ifnull for filling the blanks
select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress,
ifnull(a.PropertyAddress, b.PropertyAddress) newprop
from nashvillehousing a
join nashvillehousing b
	on a.ParcelID=b.ParcelID
	and a.RecordID<>b.RecordID
where a.PropertyAddress is null;

-- use update to fill the blanks
update nashvillehousing a
join nashvillehousing b
	on a.ParcelID=b.ParcelID
	and a.RecordID<>b.RecordID
set a.PropertyAddress=ifnull(a.PropertyAddress, b.PropertyAddress)
where a.PropertyAddress is null;

-- ----------------------------------------------------------------------------------------------

-- breaking the PropertyAddress and Owner Address into individual columns (address, city, states)
-- PropertyAddress
select PropertyAddress
from nashvillehousing;

select 
PropertyAddress, 
 Address,
SUBSTRING(PropertyAddress, LOCATE(",",PropertyAddress)+1, LENGTH(PropertyAddress)) Address
from nashvillehousing;

alter table nashvillehousing
add PropertySplitAddress varchar(255);

update nashvillehousing
set PropertySplitAddress = SUBSTRING(PropertyAddress, 1, LOCATE(",",PropertyAddress)-1);

alter table nashvillehousing
add PropertySplitCity varchar(255);

update nashvillehousing
set PropertySplitCity = SUBSTRING(PropertyAddress, LOCATE(",",PropertyAddress)+1, LENGTH(PropertyAddress));
 
-- OwnerAddress using SUBSTRING_INDEX(str,delim,count)
select OwnerAddress,
SUBSTRING_INDEX(OwnerAddress,",",1) address,
SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress,",",2), ",", -1) city,
SUBSTRING_INDEX(OwnerAddress,",",-1) state
from nashvillehousing;

alter table nashvillehousing
add OwnerSplitAddress varchar(255);

update nashvillehousing
set OwnerSplitAddress = SUBSTRING_INDEX(OwnerAddress,",",1);

alter table nashvillehousing
add OwnerSplitCity varchar(255);

update nashvillehousing
set OwnerSplitCity = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress,",",2), ",", -1);

alter table nashvillehousing
add OwnerSplitState varchar(255);

update nashvillehousing
set OwnerSplitState = SUBSTRING_INDEX(OwnerAddress,",",-1);

-- ----------------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in "SoldAsVacant" FIELDS
select DISTINCT SoldAsVacant, count(1)
from nashvillehousing
group by 1;

select SoldAsVacant,
case 
	when SoldAsVacant = 'Y' then 'Yes'
	when SoldAsVacant = 'N' then 'No'
else SoldAsVacant
end
from nashvillehousing;

update nashvillehousing
set SoldAsVacant = case 
	when SoldAsVacant = 'Y' then 'Yes'
	when SoldAsVacant = 'N' then 'No'
else SoldAsVacant
end;

-- ----------------------------------------------------------------------------------------------

-- remove duplicates using CTE (not standard practice to delete the original data, should be using temp table)
-- should be using views for best practice
delete a.*
from nashvillehousing a
inner join
(
with RowNumCTE as (
select recordid,
	ROW_NUMBER() OVER (
	PARTITION BY 
		ParcelID,
		PropertyAddress,
		SalePrice,
		SaleDate,
		LegalReference
		order by RecordID
		) row_num
from nashvillehousing
)
select * 
from rownumcte
where row_num>1) b on a.RecordID=b.RecordID
;

-- ----------------------------------------------------------------------------------------------

-- delete unused COLUMNS (not standard practice, better using views)
-- 
alter table nashvillehousing
drop column OwnerAddress, 
drop column TaxDistrict, 
drop column PropertyAddress;

select * from nashvillehousing;
