xquery version "1.0-ml";
 
module namespace cd = "http://check-database" ;

declare function cd:check-database() {
    let $db := xdmp:database()
    let $db-name := xdmp:database-name($db)
    return 
        if ($db-name = "Security")
        then ()
        else (
            (<div><h1>Wrong Database</h1><p>Please run against security database.</p></div>),
            fn:error(xs:QName("WRONGDB"), "Pleae run against the Security database."))
};