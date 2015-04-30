#Data Explore


##About 

###Why?

* You have data stored in MarkLogic
* You may or may not know a lot of the data model
* You need to see the xml, but want to perform lots of searches over it

###How?

* Data Explore allows you to leverage MarkLogic's search options
* Data Explore allows special documents to be created to better search **your** data


## Getting Started

### Deployment
* Requires MarkLogic, Java, and Ant

1. Edit install.properties
2. Change 'hostname' to deploy target instance IP or hostname.
3. Change 'securityuser' and 'securitypassword' to your credentials on that ML instance
4. Change 'port' to an *xdbc server* you can deploy via
5. Run the command 'ant' from the project's root folder

### Usage:
* Give the data-explorer role to anyone who is not an admin that requires access to the app.
* Search Options - The default search options are in place. There is also a 'inDir' search option that allows you to do directory queries from the search box