# Example of passing a SQLite database with your app, and querying it

Sometimes, you have an app that would really benefit from an included database.
But perhaps it's just a single screen, and it doesn't justify including someone
else's framework.

Please check the supplied code for an example of where the user starts to type
a city name, and a list of cities appears below that.

# To create your own database

You'll undoubtedly want to play around and create your own database. Below is a
description of how the included cities.sqlite database was made.

First, download:
http://unstats.un.org/unsd/demographic/products/dyb/dyb2012/Table08.xls

Open in Excel, then:
* Delete header
* Delete all columns except the first one
* Save as CSV Comma-delimited UTF8

Then prepare the database. You need sqlite for that. Install it with:

   $ brew install sqlite

Then in the same directory as your CSV file:

    $ sqlite3 cities.sqlite
    sqlite> CREATE TABLE cities(name TEXT PRIMARY KEY ASC);
    sqlite> .mode csv
    sqlite> .import cities.csv cities

You get a couple dozen of inserts failed but that doesn't matter in this
project; we need a basic lookup and that is all.

See if it succeeded:

    sqlite> select count(*) from cities;
    3849
    sqlite> .exit

Now you can include the file in your Xcode project and query it.