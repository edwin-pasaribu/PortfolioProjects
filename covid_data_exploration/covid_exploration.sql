-- use database
use porto_covid;

-- checking the covid deaths data
select cd.* 
from covid_deaths cd 
limit 100;
-- checking covid deaths rows (164030 rows in csv)
select count(*)
from covid_deaths cd;

-- checking the covid vacc data
select cv.* 
from covid_vaccinations cv  
limit 100;
-- checking covid vacc rows (164030 rows in csv)
select count(*)
from covid_vaccinations cv;

-- checking cases and deaths per date per location
select 
location,
date,
total_cases,
new_cases,
total_deaths,
population
from porto_covid.covid_deaths cd 
group by 1,2;

## checking death percentage on indonesia
select 
location,
date,
total_cases,
total_deaths,
(total_deaths /total_cases)*100 as DeathPercent
from porto_covid.covid_deaths cd
where location="Indonesia"
group by 1,2

## total cases vs population
select 
location,
population,
max(total_cases) as HighestInfectionCount,
max(total_cases /population)*100 as PercentPopulationInfected
from porto_covid.covid_deaths cd
-- where location="Indonesia"
group by 1,2
order by PercentPopulationInfected desc

-- found some anomalies on location data, checking for distinction
select distinct 
continent,
location
from covid_deaths cd;

-- location(country name) turns out have continent name and income range 
-- will filter out those in future queries

-- Countries with highest deathcount per population
select
continent,
location,
max(total_deaths) as TotalDeathCount
from porto_covid.covid_deaths cd
where continent <>"" and location not like "%income%"
group by 1,2
order by TotalDeathCount desc

## Continents with highest deathcount per population
select
location,
max(total_deaths) as TotalDeathCount
from porto_covid.covid_deaths cd
where continent =""
group by 1
order by TotalDeathCount desc

## income based with highest deathcount per population
select
location,
max(total_deaths) as TotalDeathCount
from porto_covid.covid_deaths cd
where location like "%income%"
group by 1
order by TotalDeathCount desc

## Global numbers total deaths and percentage
select
date,
sum(total_cases) as total_cases,
sum(total_deaths) as total_deaths,
(sum(total_deaths)/sum(total_cases))*100 as deathPercentage
from porto_covid.covid_deaths cd
where continent<>"" and location not like "%income%"
group by 1
order by date

## Global numbers new cases, new deaths and percentage
select
date,
sum(new_cases) as new_cases,
sum(new_deaths) as new_deaths,
(sum(new_cases)/sum(new_deaths))*100 as deathPercentage
from porto_covid.covid_deaths cd
where continent<>"" and location not like "%income%"
group by 1
order by date

-- total population vs vaccination
select 
cd.continent,
cd.location,
cd.date,
cd.population,
cv.new_vaccinations,
-- rollover sum vaccination
sum(cv.new_vaccinations) over 
	(partition by cd.location order by cd.location, cd.date) as rollingPeopleVacc
from covid_deaths cd 
inner join covid_vaccinations cv 
on cd.location =cv.location and cd.`date` =cv.`date`
where cd.continent <>"" and cd.location not like "%income%"
order by 2,3

-- use cte to count rolling vaccination percentage
with popvsvac (continent, location, date, population, new_vaccinations, rollingPeopleVacc)
as
(
	select 
	cd.continent,
	cd.location,
	cd.date,
	cd.population,
	cv.new_vaccinations,
	sum(cv.new_vaccinations) over 
		(partition by cd.location order by cd.location, cd.date) as rollingPeopleVacc
	from covid_deaths cd 
	inner join covid_vaccinations cv 
	on cd.location =cv.location and cd.`date` =cv.`date`
	where cd.continent <>"" and cd.location not like "%income%"
)
select *, (rollingPeopleVacc/population)*100 as rollvac_percent
from popvsvac; 

-- use temp table to count rolling vaccination percentage
drop temporary table if exists tmp_roll;
create temporary table tmp_roll
as 
(
	select 
	cd.continent,
	cd.location,
	cd.date,
	cd.population,
	cv.new_vaccinations,
	sum(cv.new_vaccinations) over 
		(partition by cd.location order by cd.location, cd.date) as rollingPeopleVacc
	from covid_deaths cd 
	inner join covid_vaccinations cv 
	on cd.location =cv.location and cd.`date` =cv.`date`
	where cd.continent <>"" and cd.location not like "%income%"

);
select *, round((rollingPeopleVacc/population),4)*100 as rollvac_percent
from tmp_roll;

-- create view for future vis in tableau
create or replace view `porto_covid`.`perc_pop_vacc` as
select
    `cd`.`continent` as `continent`,
    `cd`.`location` as `location`,
    `cd`.`date` as `date`,
    `cd`.`population` as `population`,
    `cv`.`new_vaccinations` as `new_vaccinations`,
    sum(`cv`.`new_vaccinations`) over (partition by `cd`.`location`
order by
    `cd`.`location`,
    `cd`.`date` ) as `rollingPeopleVacc`
from
    (`porto_covid`.`covid_deaths` `cd`
join `porto_covid`.`covid_vaccinations` `cv` on
    (((`cd`.`location` = `cv`.`location`)
        and (`cd`.`date` = `cv`.`date`))))
where
    ((`cd`.`continent` <> '')
        and (not((`cd`.`location` like '%income%'))))
order by
    `cd`.`location`,
    `cd`.`date`;
