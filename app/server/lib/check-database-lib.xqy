xquery version "1.0-ml";
 
module namespace check-database-lib = "http://marklogic.com/data-explore/lib/check-database-lib" ;

declare function check-database-lib:check-database() {
    let $db := xdmp:database()
    let $db-name := xdmp:database-name($db)
    return 
        if ($db-name = "Security")
        then ()
        else (
            (<div><h1>Wrong Database</h1><p>Please run against security database.</p></div>),
            fn:error(xs:QName("WRONGDB"), "Pleae run against the Security database."))
};