# Argentinean "Quiniela" SQL

One of the most popular Argentinean lotteries is called "Quiniela", where people can bet from any location in the country and it takes place four times a day. People can bet on any number, at any range of positions (1 to 20), for a specific period of the day (4 of them), province in which the lottery takes place, and number of digits.

For example, one person can place a bet of $10 to the number 1234, position 1, Quiniela nacional at the period "vespertina". Another example, could be the exact same, but only betting at the number 12.

The "Quiniela" pays as follows (for position 1):
- 4 digits right -right to left-: 3.500 times what has been bet.
- 3 digits right -right to left-: 600 times what has been bet.
- 2 digits right -right to left-: 70 times what has been bet.
- 1 digit right -right to left-: 7 times what has been bet.

Full range of betting options and their pay, can be found in: https://www.laquinieladetucuman.com.ar/quiniela-nacional/cuanto-paga-premios

## Project objective

This project aims to explore, append to one unique table, and clean a raw dataset with lottery ("Quiniela") data using SQL with MySQL.

*Source* : https://www.nacionalloteria.com/argentina/quinielas.php<br>
*Datasets*: in "data_source" folder (downloaded with web scraper: https://github.com/A-M-Perez/Quiniela_scraper)

## Data dictionary (scraped data)

- ***date***: This field contains the date in which the lottery took place. Values can be duplicated, each for a different Quiniela, Period, and Result position. Values should of type DATE.

- ***quiniela***: This field contains the name of the "Quiniela" (lottery), usually referring to the province in which it took place, or "nacional", meaning nation wide. Values can be duplicated, since the same lottery encompasses different dates, Periods, and results. Values are of type TEXT. See possible values in the scraper file's comments.

- ***period***: This field contains the name of the period (time of the day) in which the lottery took place. Values can be duplicated since periods repeat in different dates. Possible values are "primera" (earliest in the morning), "matutina" (early afternoon), "vespertina" (afternoon), "nocturna" (night). Values are of type TEXT.

- ***position***: This field contains the position number in which the result was drawn. There are 20 -4 digit- numbers drawn in each Quiniela, Period and date. Values can be duplicated since every Quiniela and Period have the same number of positions. Values are of type NUMBER.

- ***result***: This field contains the result for the specific lottery and position. Values cannot be duplicated for the same Quiniela, Period and date. Values are of type NUMBER and should integers of 4 digits.

## Repository overview / structure

├── README.md\
├── SQL_quiniela_stats.sql\
├── data_source (scraped data results)\
&emsp;&emsp;├── buenos-aires-primera.csv\
&emsp;&emsp;├── buenos-aires-matutina.csv\
&emsp;&emsp;├── buenos-aires-vespertina.csv\
&emsp;&emsp;├── buenos-aires-nocturna.csv\
&emsp;&emsp;├── nacional-primera.csv\
&emsp;&emsp;├── nacional-matutina.csv\
&emsp;&emsp;├── nacional-vespertina.csv\
&emsp;&emsp;├── nacional-nocturna.csv

## Steps taken in the process

*All steps detailed below have their corresponding reference to that in the commented SQL code*

><br>
> - Create Database (1)
><br><br>
> - Import individual tables using the 'Table Data Import Wizard'
><br><br>
> - Create a Function to return the full 'UNION ALL' code, to be executed by a Stored Procedure (2)
><br><br>
> - Create a Stored Procedure to execute the Function from step 2 (4)
><br><br>
> - Explore, analyze and clean data, to determine which steps related to Data Cleaning should be included in the Stored Procedure (3)
><br><br>
> - Update the Stored Procedure to also include all relevant exploration and cleaning steps of the process (4)
><br><br>
> - Execute the Stored Procedure and export the generated table as .CSV using the 'Table Data Export Wizard' (5)
><br>

## How this project helped me grow:

One of the challenges in this project was, at first, to think of a way to automate the entire process -in case someone else decided to use the code on different tables-, making it easy to use.
Another challenge was to determine which 'cleaning steps' were required and should be applied to any situation regardless of the tables the user is working with.

To overcome these challenges, I decided to take a methodic approach, dividing the code in mainly 3 section, where I would create the most extensive piece of code in a Function, test it out in the (final) Stored Procedure, analyze the data to determine which steps were necessary to clean it, and finally, go back to the Stored Procedure to add these required steps.

Working with just one Stored Procedure encompassing the whole code required to transform the data, was an upgrade to my SQL skills, and for that, I have to thank the whole Internet community!

## Final considerations

This project is only aimed at working with data scraped using my own web scraper (see link in the 'Project objective' section), and will probably not work with a different dataset.