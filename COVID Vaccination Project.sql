/*
Data Exploration of COVID-19 
Source:  https://ourworldindata.org/covid-deaths
Skills Used: Joins, Aggregate Functions, Windows Functions, CTE's
*/

/*
Split the data into Covid Deaths and Covid Vaccinations
*/

--Viewing the Covid Deaths Data

select *
from PortfolioProject.dbo.CovidDeaths
order by 3,4

--Viewing the Covid Vaccinations Data

select *
from PortfolioProject.dbo.CovidVaccinations
order by 3,4

-- Select data that we are going to be using

select Location,date, total_cases, new_cases, total_deaths, population
from PortfolioProject.dbo.CovidDeaths
order by 1,2

/*
Finding Case and Death Percentage in Australia
*/
-- Shows the percentage of population that contracted COVID in Australia

select Location, date, population, total_cases, (total_cases/population)*100 as DeathPercentage
from PortfolioProject.dbo.CovidDeaths
where location like '%Australia%'
order by 1,2

-- Shows the likelihood of dying if you contract COVID in Australia

select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathRate
from PortfolioProject.dbo.CovidDeaths
where location like '%Australia%'
order by 5 desc

--Looking at countries with highest infection rate

select location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
from PortfolioProject.dbo.CovidDeaths
group by location, population
order by 4 desc

-- Finding Death Count of each country

select location, MAX(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject.dbo.CovidDeaths
where continent is NOT null 
--In the dataset, when continent is NULL, the location becomes the continent. Therefore, removing the null continent values is essential
group by location
order by 2 desc

-- Showing CONTINENTS with the highest death count per population

select continent, MAX(cast(total_deaths as int)) as HighestDeathCount
from PortfolioProject.dbo.CovidDeaths
where continent is not null 
-- Here, we are grouping them by continent. Since continent has null values, the location column will have the continent death count
group by continent
order by 2 desc

/*
GLOBAL NUMBERS
*/
-- Checking the new cases and new deaths everyday

select date, sum(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercent
from PortfolioProject.dbo.CovidDeaths
--where location like '%Australia%'
where continent is not null
group by date
order by 1,2

-- The total cases across the world

select sum(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercent
from PortfolioProject.dbo.CovidDeaths
--where location like '%Australia%'
where continent is not null
--group by date
order by 1,2

/*
Joining the 2 table based on location and date
*/
-- Looking at the total popuolation vs vaccinated

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from PortfolioProject.dbo.CovidDeaths dea
join PortfolioProject.dbo.CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is NOT NULL
order by 2,3

-- Rolling count on the new_vaccination over locations only runs through one country, once a new country is encountered, the rolling count is ended

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as int)) OVER
(partition by dea.location)
from PortfolioProject.dbo.CovidDeaths dea
join PortfolioProject.dbo.CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is NOT NULL
order by 2,3


-- Since we have partion by both location and date

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as int)) OVER
(partition by dea.location order by dea.location, dea.date) as RollingVaccination
from PortfolioProject.dbo.CovidDeaths dea
join PortfolioProject.dbo.CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is NOT NULL
order by 2,3

--Since we have the total count of people vaccinated in each country, now we can find the percentage of people vaccinated in that country
--USING CTE

With popvsvac (Continent, Location, Date, Population, new_vaccinations, RollingPeopleVaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as int)) OVER
(partition by dea.location order by dea.location, dea.date) as RollingVaccination
from PortfolioProject.dbo.CovidDeaths dea
join PortfolioProject.dbo.CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is NOT NULL
--order by 2,3
)
select *, (RollingPeopleVaccinated/Population)*100 as VacPer
from popvsvac

-- Creating a view to store for tablaeu

Create view PercentpopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as int)) OVER
(partition by dea.location order by dea.location, dea.date) as RollingVaccination
from PortfolioProject.dbo.CovidDeaths dea
join PortfolioProject.dbo.CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is NOT NULL
--order by 2,3

select *
from PercentpopulationVaccinated